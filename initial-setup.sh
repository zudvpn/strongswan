#!/bin/sh -e

if [ -e /etc/ipsec.d/ipsec.conf ]; then
    echo "VPN has already been setup!"
    exit 0
fi

echo "Initializing..."
VPN_PASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo '')
echo ${VPN_PASSWORD} > /etc/ipsec.d/client.password

touch /etc/ipsec.d/triplets.dat
cat > /etc/ipsec.d/ipsec.conf <<_EOF_
config setup
    uniqueids=never
    charondebug="ike 2, knl 2, cfg 2, net 2, esp 2, dmn 2,  mgr 2"

conn %default
    fragmentation=yes
    rekey=no
    dpdaction=clear
    keyexchange=ikev2
    compress=yes
    dpddelay=21600s

    ike=${IKE_CIPHERS}
    esp=${ESP_CIPHERS}

    left=%any
    leftauth=pubkey
    leftid="${VPN_DOMAIN}"
    leftcert=fullchain.pem
    leftsendcert=always
    leftsubnet=0.0.0.0/0,::/0

    right=%any
    rightauth=eap-mschapv2
    rightsourceip=${VPN_NETWORK_IPV4},${VPN_NETWORK_IPV6}
    rightdns=${VPN_DNS}
    eap_identity=%identity

conn ikev2-pubkey
    auto=add
_EOF_

cat > /etc/ipsec.d/ipsec.secrets <<_EOF_
: ECDSA "privkey.pem"
vpn : EAP "${VPN_PASSWORD}"
_EOF_

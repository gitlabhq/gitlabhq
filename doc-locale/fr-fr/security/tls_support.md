---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Prise en charge de TLS
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab fait de la sécurité des transmissions de données entre les utilisateurs et la plateforme une priorité, en employant le protocole Transport Layer Security (TLS) pour protéger les informations lors de leur transit sur Internet.

Face à l'évolution constante des menaces de cybersécurité, GitLab s'engage à maintenir les plus hauts standards de sécurité. GitLab met régulièrement à jour la prise en charge de TLS afin de garantir que toutes les communications avec les services GitLab utilisent les méthodes de chiffrement les plus sécurisées et les plus récentes disponibles.

Ce document présente la prise en charge actuelle de TLS dans GitLab, notamment les versions et les suites de chiffrement utilisées pour assurer la sécurité de vos données.

## Protocoles pris en charge {#supported-protocols}

GitLab prend en charge TLS 1.2 et les versions supérieures pour les communications sécurisées. Cela signifie que TLS 1.2 et TLS 1.3 sont entièrement pris en charge et recommandés pour une utilisation avec GitLab.

Les protocoles plus anciens tels que TLS 1.1, TLS 1.0 et toutes les versions de SSL ne sont pas pris en charge en raison de vulnérabilités de sécurité connues. En imposant l'utilisation de TLS 1.2 et des versions supérieures, GitLab garantit un niveau élevé de sécurité pour toutes les transmissions de données et les interactions avec la plateforme.

## Suites de chiffrement prises en charge {#supported-cipher-suites}

GitLab prend en charge plusieurs suites de chiffrement. Chacune des suites de chiffrement suivantes est considérée comme sécurisée et possède une [classification de serveur SSL](https://github.com/ssllabs/research/wiki/SSL-Server-Rating-Guide) de `A`.

| Version du protocole | Suite de chiffrement |
|------------------|--------------|
| TLSv1.3 | TLS_AKE_WITH_AES_128_GCM_SHA256 |
| TLSv1.3 | TLS_AKE_WITH_AES_256_GCM_SHA384 |
| TLSv1.3 | TLS_AKE_WITH_CHACHA20_POLY1305_SHA256 |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256 |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256-draft |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA |
| TLSv1.2 | TLS_RSA_WITH_AES_128_GCM_SHA256 |
| TLSv1.2 | TLS_RSA_WITH_AES_128_CBC_SHA |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA |
| TLSv1.2 | TLS_RSA_WITH_AES_256_GCM_SHA384 |
| TLSv1.2 | TLS_RSA_WITH_AES_256_CBC_SHA |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256 |
| TLSv1.2 | TLS_RSA_WITH_AES_128_CBC_SHA256 |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384 |
| TLSv1.2 | TLS_RSA_WITH_AES_256_CBC_SHA256 |

## Exigences relatives aux certificats {#certificate-requirements}

OpenSSL 3 a relevé le [niveau de sécurité par défaut du niveau 1 au niveau 2](https://docs.openssl.org/3.0/man3/SSL_CTX_set_security_level/#default-callback-behaviour), faisant passer le nombre de bits de sécurité de 80 à 112. Par conséquent, les clés RSA, DSA et DH de moins de 2 048 bits et les clés ECC de moins de 224 bits sont interdites. GitLab ne parviendra pas à se connecter à un service utilisant un certificat signé avec un nombre de bits insuffisant et affichera un message d'erreur `certificate key too weak`.

Vous devez utiliser au moins 128 bits de sécurité. Cela implique d'utiliser des clés RSA, DSA et DH d'au moins 3 072 bits, et des clés ECC de plus de 256 bits.

| Type de clé | Longueur de clé (bits) | Statut      |
|----------|-------------------|-------------|
| RSA      | 1024              | Interdit  |
| RSA      | 2048              | Pris en charge   |
| RSA      | 3072              | Recommandé |
| RSA      | 4096              | Recommandé |
| DSA      | 1024              | Interdit  |
| DSA      | 2048              | Pris en charge   |
| DSA      | 3072              | Recommandé |
| ECC      | 192               | Interdit  |
| ECC      | 224               | Pris en charge   |
| ECC      | 256               | Recommandé |
| ECC      | 384               | Recommandé |

## Version d'OpenSSL et exigences TLS {#openssl-version-and-tls-requirements}

GitLab 17.7 et versions ultérieures utilisent OpenSSL version 3. Tous les composants fournis avec le package Linux sont compatibles avec OpenSSL 3. Cependant, avant de procéder à la mise à niveau vers GitLab 17.7, consultez le [guide OpenSSL 3](https://docs.gitlab.com/omnibus/settings/ssl/openssl_3/) pour identifier et évaluer la compatibilité de vos intégrations externes.

## Contournement de l'exigence OpenSSL 3 pour `close_notify` {#bypassing-the-openssl-3-requirement-for-close_notify}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181759) dans GitLab 17.10 et rétroporté vers GitLab 17.9.1, 17.8.4 et 17.7.6.

{{< /history >}}

[Conformément à la RFC 52460](https://www.rfc-editor.org/rfc/rfc5246#section-7.2.1), une connexion SSL doit être terminée par un message `close_notify`. OpenSSL 3 applique cette règle en tant que mesure de sécurité. Certains services, tels que les fournisseurs S3 tiers, peuvent signaler une erreur `unexpected eof while reading` en raison de cette contrainte.

Cette exigence peut être désactivée en définissant la [variable d'environnement](../administration/environment_variables.md) `SSL_IGNORE_UNEXPECTED_EOF` sur `true`. Cette solution n'est prévue qu'à titre de contournement temporaire. La désactivation de cette option peut introduire une vulnérabilité de sécurité face aux attaques par troncature.

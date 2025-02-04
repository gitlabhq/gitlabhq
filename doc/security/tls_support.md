---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: TLS support
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

GitLab prioritizes the security of data transmission between users and our
platforms by employing Transport Layer Security (TLS) to safeguard information
as it travels across the internet.

As cybersecurity threats continue to evolve, GitLab remains committed to maintaining the
highest standards of security. We regularly update our TLS support to ensure
that all communications with GitLab services are protected using the most secure
and up-to-date encryption methods available.

This document outlines the current TLS support in GitLab, including the versions
and cipher suites we use to keep your data safe and secure.

## Supported protocols

GitLab supports TLS 1.2 and higher versions for secure communications. This
means that TLS 1.2 and TLS 1.3 are fully supported and recommended for use with
GitLab.

Older protocols such as TLS 1.1, TLS 1.0, and all versions of SSL are not
supported due to known security vulnerabilities. By enforcing the use of TLS 1.2
and higher, GitLab ensures a high level of security for all data transmissions
and interactions with the platform.

## Supported cipher suites

GitLab supports the following cipher suites and protocol versions:

| Protocol Version | Cipher Suite | [Grade](https://github.com/ssllabs/research/wiki/SSL-Server-Rating-Guide) |
|------------------|--------------|-------|
| TLSv1.3 | TLS_AKE_WITH_AES_128_GCM_SHA256 | A |
| TLSv1.3 | TLS_AKE_WITH_AES_256_GCM_SHA384 | A |
| TLSv1.3 | TLS_AKE_WITH_CHACHA20_POLY1305_SHA256 | A |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 | A |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256 | A |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256-draft | A |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA | A |
| TLSv1.2 | TLS_RSA_WITH_AES_128_GCM_SHA256 | A |
| TLSv1.2 | TLS_RSA_WITH_AES_128_CBC_SHA | A |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 | A |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA | A |
| TLSv1.2 | TLS_RSA_WITH_AES_256_GCM_SHA384 | A |
| TLSv1.2 | TLS_RSA_WITH_AES_256_CBC_SHA | A |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256 | A |
| TLSv1.2 | TLS_RSA_WITH_AES_128_CBC_SHA256 | A |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384 | A |
| TLSv1.2 | TLS_RSA_WITH_AES_256_CBC_SHA256 | A |

## Certificate requirements

OpenSSL 3 increased the [default security level from level 1 to 2](https://docs.openssl.org/3.0/man3/SSL_CTX_set_security_level/#default-callback-behaviour),
raising the number of bits of security from 80 to 112. As a result, RSA, DSA, and
DH keys shorter than 2048 bits and ECC keys shorter than 224 bits are
prohibited. GitLab will fail to connect to a service that uses a certificate
signed with insufficient bits with a `certificate key too weak` error message.

We strongly recommend using at least 128 bits of security. This means using RSA,
DSA, and DH keys with at least 3072 bits, and ECC keys longer than 256 bits.

| Key type | Key length (bits) | Status      |
|----------|-------------------|-------------|
| RSA      | 1024              | Prohibited  |
| RSA      | 2048              | Supported   |
| RSA      | 3072              | Recommended |
| RSA      | 4096              | Recommended |
| DSA      | 1024              | Prohibited  |
| DSA      | 2048              | Supported   |
| DSA      | 3072              | Recommended |
| ECC      | 192               | Prohibited  |
| ECC      | 224               | Supported   |
| ECC      | 256               | Recommended |
| ECC      | 384               | Recommended |

## OpenSSL version and TLS requirements

GitLab 17.7 and later use OpenSSL version 3. All components that are shipped
with the Linux package are compatible with OpenSSL 3. However, before upgrading
to GitLab 17.7, use the [OpenSSL 3 guide](https://docs.gitlab.com/omnibus/settings/ssl/openssl_3.html)
to identify and assess the compatibility of your external integrations.

---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Pages domains API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed

Endpoints for connecting custom domains and TLS certificates in [GitLab Pages](../user/project/pages/_index.md).

The GitLab Pages feature must be enabled to use these endpoints. Find out more about [administering](../administration/pages/_index.md) and [using](../user/project/pages/_index.md) the feature.

## List all Pages domains

Prerequisites:

- You must have administrator access to the instance.

Get a list of all Pages domains.

```plaintext
GET /pages/domains
```

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute           | Type            | Description                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | string          | The custom domain name for the GitLab Pages site. |
| `url`               | string          | The full URL of the Pages site, including the protocol. |
| `project_id`        | integer         | The ID of the GitLab project associated with this Pages domain. |
| `verified`          | boolean         | Indicates whether the domain has been verified. |
| `verification_code` | string          | A unique record used to verify domain ownership. |
| `enabled_until`     | date            | The date until which the domain is enabled. This updates periodically as the domain is reverified.  |
| `auto_ssl_enabled`  | boolean         | Indicates if [automatic generation](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) of SSL certificates using Let's Encrypt is enabled for this domain. |
| `certificate_expiration` | object | Information about the SSL certificate expiration. |
| `certificate_expiration.expired` | boolean | Indicates whether the SSL certificate has expired. |
| `certificate_expiration.expiration` | date | The expiration date and time of the SSL certificate. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/pages/domains"
```

Example response:

```json
[
  {
    "domain": "ssl.domain.example",
    "url": "https://ssl.domain.example",
    "project_id": 1337,
    "verified": true,
    "verification_code": "1234567890abcdef",
    "enabled_until": "2020-04-12T14:32:00.000Z",
    "auto_ssl_enabled": false,
    "certificate": {
      "expired": false,
      "expiration": "2020-04-12T14:32:00.000Z"
    }
  }
]
```

## List Pages domains

Get a list of project Pages domains. The user must have permissions to view Pages domains.

```plaintext
GET /projects/:id/pages/domains
```

Supported attributes:

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute           | Type            | Description                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | string          | The custom domain name for the GitLab Pages site. |
| `url`               | string          | The full URL of the Pages site, including the protocol. |
| `verified`          | boolean         | Indicates whether the domain has been verified. |
| `verification_code` | string          | A unique record used to verify domain ownership. |
| `enabled_until`     | date            | The date until which the domain is enabled. This updates periodically as the domain is reverified.  |
| `auto_ssl_enabled`  | boolean         | Indicates if [automatic generation](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) of SSL certificates using Let's Encrypt is enabled for this domain. |
| `certificate` | object | Information about the SSL certificate. |
| `certificate.subject` | string | The subject of the SSL certificate, typically containing information about the domain. |
| `certificate.expired` | date | Indicates whether the SSL certificate has expired (true) or is still valid (false). |
| `certificate.certificate` | string | The full SSL certificate in PEM format. |
| `certificate.certificate_text` | date | A human-readable text representation of the SSL certificate, including details such as issuer, validity period, subject, and other certificate information.  |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/pages/domains"
```

Example response:

```json
[
  {
    "domain": "www.domain.example",
    "url": "http://www.domain.example",
    "verified": true,
    "verification_code": "1234567890abcdef",
    "enabled_until": "2020-04-12T14:32:00.000Z",
    "auto_ssl_enabled": false,
  },
  {
    "domain": "ssl.domain.example",
    "url": "https://ssl.domain.example",
    "verified": true,
    "verification_code": "1234567890abcdef",
    "enabled_until": "2020-04-12T14:32:00.000Z",
    "auto_ssl_enabled": false,
    "certificate": {
      "subject": "/O=Example, Inc./OU=Example Origin CA/CN=Example Origin Certificate",
      "expired": false,
      "certificate": "-----BEGIN CERTIFICATE-----\n … \n-----END CERTIFICATE-----",
      "certificate_text": "Certificate:\n … \n"
    }
  }
]
```

## Single Pages domain

Get a single project Pages domain. The user must have permissions to view Pages domains.

```plaintext
GET /projects/:id/pages/domains/:domain
```

Supported attributes:

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `domain`  | string         | yes      | The custom domain indicated by the user  |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute           | Type            | Description                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | string          | The custom domain name for the GitLab Pages site. |
| `url`               | string          | The full URL of the Pages site, including the protocol. |
| `verified`          | boolean         | Indicates whether the domain has been verified. |
| `verification_code` | string          | A unique record used to verify domain ownership. |
| `enabled_until`     | date            | The date until which the domain is enabled. This updates periodically as the domain is reverified.  |
| `auto_ssl_enabled`  | boolean         | Indicates if [automatic generation](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) of SSL certificates using Let's Encrypt is enabled for this domain. |
| `certificate` | object | Information about the SSL certificate. |
| `certificate.subject` | string | The subject of the SSL certificate, typically containing information about the domain. |
| `certificate.expired` | date | Indicates whether the SSL certificate has expired (true) or is still valid (false). |
| `certificate.certificate` | string | The full SSL certificate in PEM format. |
| `certificate.certificate_text` | date | A human-readable text representation of the SSL certificate, including details such as issuer, validity period, subject, and other certificate information.  |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example"
```

Example response:

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "verified": true,
  "verification_code": "1234567890abcdef",
  "enabled_until": "2020-04-12T14:32:00.000Z",
  "auto_ssl_enabled": false,
  "certificate": {
    "subject": "/O=Example, Inc./OU=Example Origin CA/CN=Example Origin Certificate",
    "expired": false,
    "certificate": "-----BEGIN CERTIFICATE-----\n … \n-----END CERTIFICATE-----",
    "certificate_text": "Certificate:\n … \n"
  }
}
```

## Create new Pages domain

Creates a new Pages domain. The user must have permissions to create new Pages domains.

```plaintext
POST /projects/:id/pages/domains
```

Supported attributes:

| Attribute          | Type           | Required | Description                              |
| -------------------| -------------- | -------- | ---------------------------------------- |
| `id`               | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `domain`           | string         | yes      | The custom domain indicated by the user  |
| `auto_ssl_enabled` | boolean        | no       | Enables [automatic generation](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) of SSL certificates issued by Let's Encrypt for custom domains. |
| `certificate`      | file/string    | no       | The certificate in PEM format with intermediates following in most specific to least specific order.|
| `key`              | file/string    | no       | The certificate key in PEM format.       |

If successful, returns [`201`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute           | Type            | Description                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | string          | The custom domain name for the GitLab Pages site. |
| `url`               | string          | The full URL of the Pages site, including the protocol. |
| `verified`          | boolean         | Indicates whether the domain has been verified. |
| `verification_code` | string          | A unique record used to verify domain ownership. |
| `enabled_until`     | date            | The date until which the domain is enabled. This updates periodically as the domain is reverified.  |
| `auto_ssl_enabled`  | boolean         | Indicates if [automatic generation](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) of SSL certificates using Let's Encrypt is enabled for this domain. |
| `certificate` | object | Information about the SSL certificate. |
| `certificate.subject` | string | The subject of the SSL certificate, typically containing information about the domain. |
| `certificate.expired` | date | Indicates whether the SSL certificate has expired (true) or is still valid (false). |
| `certificate.certificate` | string | The full SSL certificate in PEM format. |
| `certificate.certificate_text` | date | A human-readable text representation of the SSL certificate, including details such as issuer, validity period, subject, and other certificate information.  |

Example requests:

Create a new Pages domain with a certificate from a `.pem` file:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "domain=ssl.domain.example" --form "certificate=@/path/to/cert.pem" \
     --form "key=@/path/to/key.pem" "https://gitlab.example.com/api/v4/projects/5/pages/domains"
```

Create a new Pages domain by using a variable containing the certificate:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "domain=ssl.domain.example" --form "certificate=$CERT_PEM" \
     --form "key=$KEY_PEM" "https://gitlab.example.com/api/v4/projects/5/pages/domains"
```

Create a new Pages domain with an [automatic certificate](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md#enabling-lets-encrypt-integration-for-your-custom-domain):

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --form "domain=ssl.domain.example" \
     --form "auto_ssl_enabled=true" "https://gitlab.example.com/api/v4/projects/5/pages/domains"
```

Example response:

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "auto_ssl_enabled": true,
  "certificate": {
    "subject": "/O=Example, Inc./OU=Example Origin CA/CN=Example Origin Certificate",
    "expired": false,
    "certificate": "-----BEGIN CERTIFICATE-----\n … \n-----END CERTIFICATE-----",
    "certificate_text": "Certificate:\n … \n"
  }
}
```

## Update Pages domain

Updates an existing project Pages domain. The user must have permissions to change an existing Pages domains.

```plaintext
PUT /projects/:id/pages/domains/:domain
```

Supported attributes:

| Attribute          | Type           | Required | Description                              |
| ------------------ | -------------- | -------- | ---------------------------------------- |
| `id`               | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `domain`           | string         | yes      | The custom domain indicated by the user  |
| `auto_ssl_enabled` | boolean        | no       | Enables [automatic generation](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) of SSL certificates issued by Let's Encrypt for custom domains. |
| `certificate`      | file/string    | no       | The certificate in PEM format with intermediates following in most specific to least specific order.|
| `key`              | file/string    | no       | The certificate key in PEM format.       |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute           | Type            | Description                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | string          | The custom domain name for the GitLab Pages site. |
| `url`               | string          | The full URL of the Pages site, including the protocol. |
| `verified`          | boolean         | Indicates whether the domain has been verified. |
| `verification_code` | string          | A unique record used to verify domain ownership. |
| `enabled_until`     | date            | The date until which the domain is enabled. This updates periodically as the domain is reverified.  |
| `auto_ssl_enabled`  | boolean         | Indicates if [automatic generation](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) of SSL certificates using Let's Encrypt is enabled for this domain. |
| `certificate` | object | Information about the SSL certificate. |
| `certificate.subject` | string | The subject of the SSL certificate, typically containing information about the domain. |
| `certificate.expired` | date | Indicates whether the SSL certificate has expired (true) or is still valid (false). |
| `certificate.certificate` | string | The full SSL certificate in PEM format. |
| `certificate.certificate_text` | date | A human-readable text representation of the SSL certificate, including details such as issuer, validity period, subject, and other certificate information.  |

### Adding certificate

Add a certificate for a Pages domain from a `.pem` file:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" --form "certificate=@/path/to/cert.pem" \
     --form "key=@/path/to/key.pem" "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example"
```

Add a certificate for a Pages domain by using a variable containing the certificate:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" --form "certificate=$CERT_PEM" \
     --form "key=$KEY_PEM" "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example"
```

Example response:

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "auto_ssl_enabled": false,
  "certificate": {
    "subject": "/O=Example, Inc./OU=Example Origin CA/CN=Example Origin Certificate",
    "expired": false,
    "certificate": "-----BEGIN CERTIFICATE-----\n … \n-----END CERTIFICATE-----",
    "certificate_text": "Certificate:\n … \n"
  }
}
```

### Enabling Let's Encrypt integration for Pages custom domains

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "auto_ssl_enabled=true" "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example"
```

Example response:

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "auto_ssl_enabled": true
}
```

### Removing certificate

To remove the SSL certificate attached to the Pages domain, run:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" --form "certificate=" \
     --form "key=" "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example"
```

Example response:

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "auto_ssl_enabled": false
}
```

## Verify Pages domain

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/21261) in GitLab 17.7.

Verifies an existing project Pages domain.
The user must have permissions to update Pages domains.

```plaintext
PUT /projects/:id/pages/domains/:domain/verify
```

Supported attributes:

| Attribute          | Type           | Required | Description                              |
| ------------------ | -------------- | -------- | ---------------------------------------- |
| `id` | integer/string | yes | The ID or URL-encoded path of the project |
| `domain` | string | yes | The custom domain to verify |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute           | Type            | Description                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | string          | The custom domain name for the GitLab Pages site. |
| `url`               | string          | The full URL of the Pages site, including the protocol. |
| `verified`          | boolean         | Indicates whether the domain has been verified. |
| `verification_code` | string          | A unique record used to verify domain ownership. |
| `enabled_until`     | date            | The date until which the domain is enabled. This updates periodically as the domain is reverified.  |
| `auto_ssl_enabled`  | boolean         | Indicates if [automatic generation](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) of SSL certificates using Let's Encrypt is enabled for this domain. |
| `certificate` | object | Information about the SSL certificate. |
| `certificate.subject` | string | The subject of the SSL certificate, typically containing information about the domain. |
| `certificate.expired` | date | Indicates whether the SSL certificate has expired (true) or is still valid (false). |
| `certificate.certificate` | string | The full SSL certificate in PEM format. |
| `certificate.certificate_text` | date | A human-readable text representation of the SSL certificate, including details such as issuer, validity period, subject, and other certificate information.  |

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example/verify"
```

Example response:

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "auto_ssl_enabled": false,
  "verified": true,
  "verification_code": "1234567890abcdef",
  "enabled_until": "2020-04-12T14:32:00.000Z"
}
```

## Delete Pages domain

Deletes an existing project Pages domain.

```plaintext
DELETE /projects/:id/pages/domains/:domain
```

Supported attributes:

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `domain`  | string         | yes      | The custom domain indicated by the user  |

If successful, a `204 No Content` HTTP response with an empty body is expected.

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example"
```

---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Pages domains API

Endpoints for connecting custom domain(s) and TLS certificates in [GitLab Pages](https://about.gitlab.com/stages-devops-lifecycle/pages/).

The GitLab Pages feature must be enabled to use these endpoints. Find out more about [administering](../administration/pages/index.md) and [using](../user/project/pages/index.md) the feature.

## List all Pages domains

Get a list of all Pages domains. The user must have admin permissions.

```plaintext
GET /pages/domains
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/pages/domains"
```

```json
[
  {
    "domain": "ssl.domain.example",
    "url": "https://ssl.domain.example",
    "project_id": 1337,
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

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/pages/domains"
```

```json
[
  {
    "domain": "www.domain.example",
    "url": "http://www.domain.example"
  },
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
]
```

## Single Pages domain

Get a single project Pages domain. The user must have permissions to view Pages domains.

```plaintext
GET /projects/:id/pages/domains/:domain
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `domain`  | string         | yes      | The custom domain indicated by the user  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/pages/domains/www.domain.example"
```

```json
{
  "domain": "www.domain.example",
  "url": "http://www.domain.example"
}
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example"
```

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

## Create new Pages domain

Creates a new Pages domain. The user must have permissions to create new Pages domains.

```plaintext
POST /projects/:id/pages/domains
```

| Attribute          | Type           | Required | Description                              |
| -------------------| -------------- | -------- | ---------------------------------------- |
| `id`               | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `domain`           | string         | yes      | The custom domain indicated by the user  |
| `auto_ssl_enabled` | boolean        | no       | Enables [automatic generation](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) of SSL certificates issued by Let's Encrypt for custom domains. |
| `certificate`      | file/string    | no       | The certificate in PEM format with intermediates following in most specific to least specific order.|
| `key`              | file/string    | no       | The certificate key in PEM format.       |

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

| Attribute          | Type           | Required | Description                              |
| ------------------ | -------------- | -------- | ---------------------------------------- |
| `id`               | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `domain`           | string         | yes      | The custom domain indicated by the user  |
| `auto_ssl_enabled` | boolean        | no       | Enables [automatic generation](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) of SSL certificates issued by Let's Encrypt for custom domains. |
| `certificate`      | file/string    | no       | The certificate in PEM format with intermediates following in most specific to least specific order.|
| `key`              | file/string    | no       | The certificate key in PEM format.       |

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

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "auto_ssl_enabled": false
}
```

## Delete Pages domain

Deletes an existing project Pages domain.

```plaintext
DELETE /projects/:id/pages/domains/:domain
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `domain`  | string         | yes      | The custom domain indicated by the user  |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example"
```

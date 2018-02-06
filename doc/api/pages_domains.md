# Pages domains API

Endpoints for connecting custom domain(s) and TLS certificates in [GitLab Pages](https://about.gitlab.com/features/pages/).

The GitLab Pages feature must be enabled to use these endpoints. Find out more about [administering](../administration/pages/index.md) and [using](../user/project/pages/index.md) the feature.

## List all pages domains

Get a list of all pages domains. The user must have admin permissions.

```http
GET /pages/domains
```

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/pages/domains
```

```json
[
  {
    "domain": "ssl.domain.example",
    "url": "https://ssl.domain.example",
    "project_id": 1337,
    "certificate": {
      "expired": false,
      "expiration": "2020-04-12T14:32:00.000Z"
    }
  }
]
```

## List pages domains

Get a list of project pages domains. The user must have permissions to view pages domains.

```http
GET /projects/:id/pages/domains
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/pages/domains
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
    "certificate": {
      "subject": "/O=Example, Inc./OU=Example Origin CA/CN=Example Origin Certificate",
      "expired": false,
      "certificate": "-----BEGIN CERTIFICATE-----\n … \n-----END CERTIFICATE-----",
      "certificate_text": "Certificate:\n … \n"
    }
  }
]
```

## Single pages domain

Get a single project pages domain. The user must have permissions to view pages domains.

```http
GET /projects/:id/pages/domains/:domain
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `domain`  | string         | yes      | The domain                               |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/pages/domains/www.domain.example
```

```json
{
  "domain": "www.domain.example",
  "url": "http://www.domain.example"
}
```

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example
```

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "certificate": {
    "subject": "/O=Example, Inc./OU=Example Origin CA/CN=Example Origin Certificate",
    "expired": false,
    "certificate": "-----BEGIN CERTIFICATE-----\n … \n-----END CERTIFICATE-----",
    "certificate_text": "Certificate:\n … \n"
  }
}
```

## Create new pages domain

Creates a new pages domain. The user must have permissions to create new pages domains.

```http
POST /projects/:id/pages/domains
```

| Attribute     | Type           | Required | Description                              |
| ------------- | -------------- | -------- | ---------------------------------------- |
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `domain`      | string         | yes      | The domain                               |
| `certificate` | file/string    | no       | The certificate in PEM format with intermediates following in most specific to least specific order.|
| `key`         | file/string    | no       | The certificate key in PEM format.       |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --form="domain=ssl.domain.example" --form="certificate=@/path/to/cert.pem" --form="key=@/path/to/key.pem" https://gitlab.example.com/api/v4/projects/5/pages/domains
```

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --form="domain=ssl.domain.example" --form="certificate=$CERT_PEM" --form="key=$KEY_PEM" https://gitlab.example.com/api/v4/projects/5/pages/domains
```

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "certificate": {
    "subject": "/O=Example, Inc./OU=Example Origin CA/CN=Example Origin Certificate",
    "expired": false,
    "certificate": "-----BEGIN CERTIFICATE-----\n … \n-----END CERTIFICATE-----",
    "certificate_text": "Certificate:\n … \n"
  }
}
```

## Update pages domain

Updates an existing project pages domain. The user must have permissions to change an existing pages domains.

```http
PUT /projects/:id/pages/domains/:domain
```

| Attribute     | Type           | Required | Description                              |
| ------------- | -------------- | -------- | ---------------------------------------- |
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `domain`      | string         | yes      | The domain                               |
| `certificate` | file/string    | no       | The certificate in PEM format with intermediates following in most specific to least specific order.|
| `key`         | file/string    | no       | The certificate key in PEM format.       |

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --form="certificate=@/path/to/cert.pem" --form="key=@/path/to/key.pem" https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example
```

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --form="certificate=$CERT_PEM" --form="key=$KEY_PEM" https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example
```

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "certificate": {
    "subject": "/O=Example, Inc./OU=Example Origin CA/CN=Example Origin Certificate",
    "expired": false,
    "certificate": "-----BEGIN CERTIFICATE-----\n … \n-----END CERTIFICATE-----",
    "certificate_text": "Certificate:\n … \n"
  }
}
```

## Delete pages domain

Deletes an existing project pages domain.

```http
DELETE /projects/:id/pages/domains/:domain
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `domain`  | string         | yes      | The domain                               |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example
```

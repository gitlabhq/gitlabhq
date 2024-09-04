---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# User SSH and GPG keys API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

You can manage [user SSH keys](../user/ssh.md) and [user GPG keys](../user/project/repository/signed_commits/gpg.md) by
using the REST API.

## List your SSH keys

Get a list of your SSH keys.

Prerequisites:

- You must be [authenticated](rest/index.md#authentication).

This endpoint takes pagination parameters `page` and `per_page` to restrict the list of keys.

```plaintext
GET /user/keys
```

Supported attributes:

- **none**

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/keys"
```

Example response:

```json
[
  {
    "id": 1,
    "title": "Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
    "created_at": "2014-08-01T14:47:39.080Z"
  },
  {
    "id": 3,
    "title": "Another Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
    "created_at": "2014-08-01T14:47:39.080Z"
  }
]
```

## List SSH keys for a user

Get a list of the specified user's SSH keys.

```plaintext
GET /users/:id_or_username/keys
```

Supported attributes:

| Attribute        | Type   | Required | Description |
|:-----------------|:-------|:---------|:------------|
| `id_or_username` | string | yes      | ID or username of the user to get the SSH keys for. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/1/keys"
```

## Get a single SSH key

Get a single SSH key.

```plaintext
GET /user/keys/:key_id
```

Supported attributes:

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `key_id`  | string | yes      | ID of an SSH key |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/keys/1"
```

Example response:

```json
{
  "id": 1,
  "title": "Public key",
  "key": "<SSH_KEY>",
  "created_at": "2014-08-01T14:47:39.080Z"
}
```

## Get a single SSH key for a user

Get a single SSH key for a given user.

```plaintext
GET /users/:id/keys/:key_id
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of specified user |
| `key_id`  | integer | yes      | SSH key ID  |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/users/1/keys/1"
```

Example response:

```json
{
  "id": 1,
  "title": "Public key",
  "key": "<SSH_KEY>",
  "created_at": "2014-08-01T14:47:39.080Z"
}
```

## Add an SSH key to your account

> - The `usage_type` parameter was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105551) in GitLab 15.7.

Create a new SSH key for your account.

Prerequisites:

- You must be [authenticated](rest/index.md#authentication).

```plaintext
POST /user/keys
```

Supported attributes:

| Attribute    | Type   | Required | Description |
|:-------------|:-------|:---------|:------------|
| `title`      | string | yes      | New SSH key's title |
| `key`        | string | yes      | New SSH key |
| `expires_at` | string | no       | Expiration date of the SSH key in ISO 8601 format (`YYYY-MM-DDTHH:MM:SSZ`) |
| `usage_type` | string | no       | Scope of usage for the SSH key: `auth`, `signing` or `auth_and_signing`. Default: `auth_and_signing` |

Returns either:

- The created key with status `201 Created` on success.
- A `400 Bad Request` error with a message explaining the error:

  ```json
  {
    "message": {
      "fingerprint": [
        "has already been taken"
      ],
      "key": [
        "has already been taken"
      ]
    }
  }
  ```

Example response:

```json
{
  "title": "ABC",
  "key": "<SSH_KEY>",
  "expires_at": "2016-01-21T00:00:00.000Z",
  "usage_type": "auth"
}
```

## Add an SSH key for a user

> - The `usage_type` parameter was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105551) in GitLab 15.7.

Create new key owned by the specified user.

NOTE:
This also adds an audit event.

Prerequisites:

- You must be an administrator.

```plaintext
POST /users/:id/keys
```

Supported attributes:

| Attribute    | Type    | Required | Description |
|:-------------|:--------|:---------|:------------|
| `id`         | integer | yes      | ID of specified user |
| `title`      | string  | yes      | New SSH key's title |
| `key`        | string  | yes      | New SSH key |
| `expires_at` | string  | no       | Expiration date of the SSH key in ISO 8601 format (`YYYY-MM-DDTHH:MM:SSZ`) |
| `usage_type` | string  | no       | Scope of usage for the SSH key: `auth`, `signing` or `auth_and_signing`. Default: `auth_and_signing` |

Returns either:

- The created key with status `201 Created` on success.
- A `400 Bad Request` error with a message explaining the error:

  ```json
  {
    "message": {
      "fingerprint": [
        "has already been taken"
      ],
      "key": [
        "has already been taken"
      ]
    }
  }
  ```

Example response:

```json
{
  "title": "ABC",
  "key": "<SSH_KEY>",
  "expires_at": "2016-01-21T00:00:00.000Z",
  "usage_type": "auth"
}
```

## Delete an SSH key from your account

Delete an SSH key from your account.

Prerequisites:

- You must be [authenticated](rest/index.md#authentication).

```plaintext
DELETE /user/keys/:key_id
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `key_id`  | integer | yes      | SSH key ID  |

Returns either:

- A `204 No Content` status code if the operation was successful.
- A `404` status code if the resource was not found.

## Delete an SSH key for a user

Delete an SSH key owned by the specified user.

Prerequisites:

- You must be an administrator.

```plaintext
DELETE /users/:id/keys/:key_id
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of specified user |
| `key_id`  | integer | yes      | SSH key ID  |

## List your GPG keys

Get a list of your GPG keys.

Prerequisites:

- You must be [authenticated](rest/index.md#authentication).

```plaintext
GET /user/gpg_keys
```

Supported attributes:

- **none**

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/gpg_keys"
```

Example response:

```json
[
  {
    "id": 1,
    "key": "<PGP_PUBLIC_KEY_BLOCK>",
    "created_at": "2017-09-05T09:17:46.264Z"
  }
]
```

## List GPG keys for a user

Get a list of the specified user's GPG keys. This endpoint can be accessed without authentication.

```plaintext
GET /users/:id/gpg_keys
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of the user |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/2/gpg_keys"
```

Example response:

```json
[
  {
    "id": 1,
    "key": "<PGP_PUBLIC_KEY_BLOCK>",
    "created_at": "2017-09-05T09:17:46.264Z"
  }
]
```

## Get a single GPG key

Get details of one of your GPG keys.

Prerequisites:

- You must be [authenticated](rest/index.md#authentication).

```plaintext
GET /user/gpg_keys/:key_id
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `key_id`  | integer | yes      | ID of the GPG key |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/gpg_keys/1"
```

Example response:

```json
{
  "id": 1,
  "key": "<PGP_PUBLIC_KEY_BLOCK>",
  "created_at": "2017-09-05T09:17:46.264Z"
}
```

## Get a single GPG key for a user

Get a specific GPG key for a given user. This endpoint can be accessed without administrator authentication.

```plaintext
GET /users/:id/gpg_keys/:key_id
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of the user |
| `key_id`  | integer | yes      | ID of the GPG key |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/2/gpg_keys/1"
```

Example response:

```json
{
  "id": 1,
  "key": "<PGP_PUBLIC_KEY_BLOCK>",
  "created_at": "2017-09-05T09:17:46.264Z"
}
```

## Add a GPG key to your account

Create a new GPG key for your account.

Prerequisites:

- You must be [authenticated](rest/index.md#authentication).

```plaintext
POST /user/gpg_keys
```

Supported attributes:

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `key`     | string | yes      | New GPG key |

Example request:

```shell
export KEY="$(gpg --armor --export <your_gpg_key_id>)"

curl --data-urlencode "key=<PGP_PUBLIC_KEY_BLOCK>" \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/user/gpg_keys"
```

Example response:

```json
[
  {
    "id": 1,
    "key": "<PGP_PUBLIC_KEY_BLOCK>",
    "created_at": "2017-09-05T09:17:46.264Z"
  }
]
```

## Add a GPG key for a user

Create new GPG key owned by the specified user.

Prerequisites:

- You must be an administrator.

```plaintext
POST /users/:id/gpg_keys
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of the user |
| `key_id`  | integer | yes      | ID of the GPG key |

Example request:

```shell
curl --data-urlencode "key=<PGP_PUBLIC_KEY_BLOCK>" \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/2/gpg_keys"
```

Example response:

```json
[
  {
    "id": 1,
    "key": "<PGP_PUBLIC_KEY_BLOCK>",
    "created_at": "2017-09-05T09:17:46.264Z"
  }
]
```

## Delete a GPG key from your account

Delete a GPG key from your account.

Prerequisites:

- You must be [authenticated](rest/index.md#authentication).

```plaintext
DELETE /user/gpg_keys/:key_id
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `key_id`  | integer | yes      | ID of the GPG key |

Returns either:

- `204 No Content` on success.
- `404 Not Found` if the key cannot be found.

## Delete a GPG key for a user

Delete a GPG key owned by a specified user.

Prerequisites:

- You must be an administrator.

```plaintext
DELETE /users/:id/gpg_keys/:key_id
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of the user |
| `key_id`  | integer | yes      | ID of the GPG key |

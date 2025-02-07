---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: User SSH and GPG keys API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use this API to interact with SSH and GPG keys for users. For more information, see [SSH keys](../user/ssh.md) and [GPG keys](../user/project/repository/signed_commits/gpg.md).

## List all SSH keys

Lists all SSH keys for your user account.

Use the `page` and `per_page` [pagination parameters](rest/_index.md#offset-based-pagination) to filter the results.

Prerequisites:

- You must be authenticated.

```plaintext
GET /user/keys
```

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
    "created_at": "2014-08-01T14:47:39.080Z",
    "usage_type": "auth"
  },
  {
    "id": 3,
    "title": "Another Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
    "created_at": "2014-08-01T14:47:39.080Z",
    "usage_type": "signing"
  }
]
```

## List all SSH keys for a user

Lists all SSH keys for a given user account. This endpoint does not require authentication.

```plaintext
GET /users/:id_or_username/keys
```

Supported attributes:

| Attribute        | Type   | Required | Description |
|:-----------------|:-------|:---------|:------------|
| `id_or_username` | string | yes      | ID or username of user account |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/1/keys"
```

## Get an SSH key

Gets an SSH key for your user account. This endpoint does not require authentication.

```plaintext
GET /user/keys/:key_id
```

Supported attributes:

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `key_id`  | string | yes      | ID of existing key |

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
  "created_at": "2014-08-01T14:47:39.080Z",
  "usage_type": "auth"
}
```

## Get an SSH key for a user

Gets an SSH key for a given user account. This endpoint does not require authentication.

```plaintext
GET /users/:id/keys/:key_id
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of user account |
| `key_id`  | integer | yes      | ID of existing key  |

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
  "created_at": "2014-08-01T14:47:39.080Z",
  "usage_type": "auth"
}
```

## Add an SSH key

> - The `usage_type` parameter was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105551) in GitLab 15.7.

Adds an SSH key for your user account.

Prerequisites:

- You must be authenticated.

```plaintext
POST /user/keys
```

Supported attributes:

| Attribute    | Type   | Required | Description |
|:-------------|:-------|:---------|:------------|
| `title`      | string | yes      | Title for key |
| `key`        | string | yes      | Public key value |
| `expires_at` | string | no       | Expiration date of the key in ISO format (`YYYY-MM-DD`). |
| `usage_type` | string | no       | Usage scope for the key. Possible values: `auth`, `signing` or `auth_and_signing`. Default value: `auth_and_signing` |

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

Adds an SSH key for a given user account.

NOTE:
This also adds an audit event.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
POST /users/:id/keys
```

Supported attributes:

| Attribute    | Type    | Required | Description |
|:-------------|:--------|:---------|:------------|
| `id`         | integer | yes      | ID of user account |
| `title`      | string  | yes      | Title for key |
| `key`        | string  | yes      | Public key value  |
| `expires_at` | string  | no       | Expiration date of the access token in ISO format (`YYYY-MM-DD`). |
| `usage_type` | string  | no       | Usage scope for the key. Possible values: `auth`, `signing` or `auth_and_signing`. Default value: `auth_and_signing` |

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

## Delete an SSH key

Deletes an SSH key from your user account.

Prerequisites:

- You must be authenticated.

```plaintext
DELETE /user/keys/:key_id
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `key_id`  | integer | yes      | ID of existing key  |

Returns either:

- A `204 No Content` status code if the operation was successful.
- A `404` status code if the resource was not found.

## Delete an SSH key for a user

Deletes an SSH key from a given user account.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
DELETE /users/:id/keys/:key_id
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of user account |
| `key_id`  | integer | yes      | ID of existing key  |

## List all GPG keys

Lists all GPG keys for your user account.

Prerequisites:

- You must be authenticated.

```plaintext
GET /user/gpg_keys
```

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

## List all GPG keys for a user

Lists all GPG keys for a given user account. This endpoint does not require authentication.

```plaintext
GET /users/:id/gpg_keys
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of user account |

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

## Get a GPG key

Gets a GPG key for your user account.

Prerequisites:

- You must be authenticated.

```plaintext
GET /user/gpg_keys/:key_id
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `key_id`  | integer | yes      | ID of existing key |

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

## Get a GPG key for a user

Gets a GPG key for a given user account. This endpoint does not require authentication.

```plaintext
GET /users/:id/gpg_keys/:key_id
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of user account |
| `key_id`  | integer | yes      | ID of existing key |

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

## Add a GPG key

Adds a GPG key for your user account.

Prerequisites:

- You must be authenticated.

```plaintext
POST /user/gpg_keys
```

Supported attributes:

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `key`     | string | yes      | Public key value |

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

Adds a GPG key for a given user account.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
POST /users/:id/gpg_keys
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of user account |
| `key`     | integer | yes      | Public key value |

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

## Delete a GPG key

Deletes a GPG key from your user account.

Prerequisites:

- You must be authenticated.

```plaintext
DELETE /user/gpg_keys/:key_id
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `key_id`  | integer | yes      | ID of existing key |

Returns either:

- `204 No Content` on success.
- `404 Not Found` if the key cannot be found.

## Delete a GPG key for a user

Deletes a GPG key from a given user account.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
DELETE /users/:id/gpg_keys/:key_id
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of user account |
| `key_id`  | integer | yes      | ID of existing key |

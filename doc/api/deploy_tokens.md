---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Deploy Tokens API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

## List all deploy tokens

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Get a list of all deploy tokens across the GitLab instance. This endpoint requires administrator access.

```plaintext
GET /deploy_tokens
```

Parameters:

| Attribute | Type     | Required               | Description |
|-----------|----------|------------------------|-------------|
| `active`  | boolean  | No | Limit by active status. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/deploy_tokens"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "MyToken",
    "username": "gitlab+deploy-token-1",
    "expires_at": "2020-02-14T00:00:00.000Z",
    "revoked": false,
    "expired": false,
    "scopes": [
      "read_repository",
      "read_registry"
    ]
  }
]
```

## Project deploy tokens

Project deploy token API endpoints require at least the Maintainer role
for the project.

### List project deploy tokens

Get a list of a project's deploy tokens.

```plaintext
GET /projects/:id/deploy_tokens
```

Parameters:

| Attribute      | Type           | Required               | Description |
|:---------------|:---------------|:-----------------------|:------------|
| `id`           | integer/string | Yes | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `active`       | boolean        | No | Limit by active status. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/deploy_tokens"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "MyToken",
    "username": "gitlab+deploy-token-1",
    "expires_at": "2020-02-14T00:00:00.000Z",
    "revoked": false,
    "expired": false,
    "scopes": [
      "read_repository",
      "read_registry"
    ]
  }
]
```

### Get a project deploy token

Get a single project's deploy token by ID.

```plaintext
GET /projects/:id/deploy_tokens/:token_id
```

Parameters:

| Attribute  | Type           | Required               | Description |
| ---------- | -------------- | ---------------------- | ----------- |
| `id`       | integer/string | Yes | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `token_id` | integer        | Yes | ID of the deploy token |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/deploy_tokens/1"
```

Example response:

```json
{
  "id": 1,
  "name": "MyToken",
  "username": "gitlab+deploy-token-1",
  "expires_at": "2020-02-14T00:00:00.000Z",
  "revoked": false,
  "expired": false,
  "scopes": [
    "read_repository",
    "read_registry"
  ]
}
```

### Create a project deploy token

Creates a new deploy token for a project.

```plaintext
POST /projects/:id/deploy_tokens
```

Parameters:

| Attribute    | Type             | Required               | Description |
| ------------ | ---------------- | ---------------------- | ----------- |
| `id`         | integer/string   | Yes | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `name`       | string           | Yes | New deploy token's name |
| `scopes`     | array of strings | Yes | Indicates the deploy token scopes. Must be at least one of `read_repository`, `read_registry`, `write_registry`, `read_package_registry`, or `write_package_registry`. |
| `expires_at` | datetime         | No | Expiration date for the deploy token. Does not expire if no value is provided. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `username`   | string           | No | Username for deploy token. Default is `gitlab+deploy-token-{n}` |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" \
     --data '{"name": "My deploy token", "expires_at": "2021-01-01", "username": "custom-user", "scopes": ["read_repository"]}' \
     "https://gitlab.example.com/api/v4/projects/5/deploy_tokens/"
```

Example response:

```json
{
  "id": 1,
  "name": "My deploy token",
  "username": "custom-user",
  "expires_at": "2021-01-01T00:00:00.000Z",
  "token": "jMRvtPNxrn3crTAGukpZ",
  "revoked": false,
  "expired": false,
  "scopes": [
    "read_repository"
  ]
}
```

### Delete a project deploy token

Removes a deploy token from the project.

```plaintext
DELETE /projects/:id/deploy_tokens/:token_id
```

Parameters:

| Attribute  | Type           | Required               | Description |
| ---------- | -------------- | ---------------------- | ----------- |
| `id`       | integer/string | Yes | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `token_id` | integer        | Yes | ID of the deploy token |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
    "https://gitlab.example.com/api/v4/projects/5/deploy_tokens/13"
```

## Group deploy tokens

Users with at least the Maintainer role for the group can list group deploy
tokens. Only group Owners can create and delete group deploy tokens.

### List group deploy tokens

Get a list of a group's deploy tokens

```plaintext
GET /groups/:id/deploy_tokens
```

Parameters:

| Attribute      | Type           | Required               | Description |
|:---------------|:---------------|:-----------------------|:------------|
| `id`           | integer/string | Yes | ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `active`       | boolean        | No | Limit by active status. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/deploy_tokens"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "MyToken",
    "username": "gitlab+deploy-token-1",
    "expires_at": "2020-02-14T00:00:00.000Z",
    "revoked": false,
    "expired": false,
    "scopes": [
      "read_repository",
      "read_registry"
    ]
  }
]
```

### Get a group deploy token

Get a single group's deploy token by ID.

```plaintext
GET /groups/:id/deploy_tokens/:token_id
```

Parameters:

| Attribute   | Type           | Required               | Description |
| ----------- | -------------- | ---------------------- | ----------- |
| `id`        | integer/string | Yes | ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `token_id`  | integer        | Yes | ID of the deploy token |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/deploy_tokens/1"
```

Example response:

```json
{
  "id": 1,
  "name": "MyToken",
  "username": "gitlab+deploy-token-1",
  "expires_at": "2020-02-14T00:00:00.000Z",
  "revoked": false,
  "expired": false,
  "scopes": [
    "read_repository",
    "read_registry"
  ]
}
```

### Create a group deploy token

Creates a new deploy token for a group.

```plaintext
POST /groups/:id/deploy_tokens
```

Parameters:

| Attribute    | Type | Required  | Description |
| ------------ | ---- | --------- | ----------- |
| `id`         | integer/string   | Yes | ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `name`       | string           | Yes | New deploy token's name |
| `scopes`     | array of strings | Yes | Indicates the deploy token scopes. Must be at least one of `read_repository`, `read_registry`, `write_registry`, `read_package_registry`, or `write_package_registry`. |
| `expires_at` | datetime         | No | Expiration date for the deploy token. Does not expire if no value is provided. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `username`   | string           | No | Username for deploy token. Default is `gitlab+deploy-token-{n}` |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" \
     --data '{"name": "My deploy token", "expires_at": "2021-01-01", "username": "custom-user", "scopes": ["read_repository"]}' \
     "https://gitlab.example.com/api/v4/groups/5/deploy_tokens/"
```

Example response:

```json
{
  "id": 1,
  "name": "My deploy token",
  "username": "custom-user",
  "expires_at": "2021-01-01T00:00:00.000Z",
  "token": "jMRvtPNxrn3crTAGukpZ",
  "revoked": false,
  "expired": false,
  "scopes": [
    "read_registry"
  ]
}
```

### Delete a group deploy token

Removes a deploy token from the group.

```plaintext
DELETE /groups/:id/deploy_tokens/:token_id
```

Parameters:

| Attribute   | Type           | Required               | Description |
| ----------- | -------------- | ---------------------- | ----------- |
| `id`        | integer/string | Yes | ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `token_id`  | integer        | Yes | ID of the deploy token |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/deploy_tokens/13"
```

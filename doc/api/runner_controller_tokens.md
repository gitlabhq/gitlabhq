---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Runner controller tokens API
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.
> This feature is available for testing, but not ready for production use.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218229) in GitLab 18.9 [with a flag](../administration/feature_flags/_index.md) named `FF_USE_JOB_ROUTER`. This feature is an [experiment](../policy/development_stages_support.md) and subject to the [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

{{< /history >}}

The runner controller tokens API allows you to manage authentication tokens for runner controllers.
Runner controllers use these tokens to authenticate with the GitLab instance and manage runners.
This API provides endpoints to create, list, rotate, and revoke tokens.

Prerequisites:

- You must have administrator access to the GitLab instance.

## List all runner controller tokens

Lists all runner controller tokens.

```plaintext
GET /runner_controllers/:id/tokens
```

Parameters:

| Attribute          | Type         | Required | Description |
|--------------------|--------------|----------|-------------|
| `id`               | integer      | Yes      | The ID of the runner controller. |

Response:

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute               | Type    | Description |
|-------------------------|---------|-------------|
| `id`                    | integer | The unique identifier of the runner controller token. |
| `runner_controller_id`  | integer | The ID of the associated runner controller. |
| `description`           | string  | A description for the token. |
| `created_at`            | datetime| The date and time when the token was created. |
| `updated_at`            | datetime| The date and time when the token was last updated. |

Example request:

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/:id/tokens"
```

Example response:

```json
[
    {
        "id": 1,
        "runner_controller_id": 1,
        "description": "Token for runner controller",
        "created_at": "2026-01-01T00:00:00Z",
        "updated_at": "2026-01-02T00:00:00Z"
    },
    {
        "id": 2,
        "runner_controller_id": 1,
        "description": "Another token for runner controller",
        "created_at": "2026-01-03T00:00:00Z",
        "updated_at": "2026-01-04T00:00:00Z"
    }
]
```

## Retrieve a single runner controller token

Retrieves details of a specific runner controller token by its ID.

```plaintext
GET /runner_controllers/:id/tokens/:token_id
```

Parameters:

| Attribute          | Type         | Required | Description |
|--------------------|--------------|----------|-------------|
| `id`               | integer      | Yes      | The ID of the runner controller. |
| `token_id`         | integer      | Yes      | The ID of the runner controller token. |

Response:

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) with the following fields:

| Attribute               | Type    | Description |
|-------------------------|---------|-------------|
| `id`                    | integer | The unique identifier of the runner controller token. |
| `runner_controller_id`  | integer | The ID of the associated runner controller. |
| `description`           | string  | A description for the token. |
| `created_at`            | datetime| The date and time when the token was created. |
| `updated_at`            | datetime| The date and time when the token was last updated. |

Example request:

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/:id/tokens/:token_id"
```

Example response:

```json
{
    "id": 1,
    "runner_controller_id": 1,
    "description": "Token for runner controller",
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-02T00:00:00Z"
}
```

## Create a runner controller token

Creates a new runner controller token.

```plaintext
POST /runner_controllers/:id/tokens
```

Parameters:

| Attribute          | Type         | Required | Description |
|--------------------|--------------|----------|-------------|
| `id`               | integer      | Yes      | The ID of the runner controller. |

Supported attributes:

| Attribute          | Type         | Required | Description |
|--------------------|--------------|----------|-------------|
| `description`      | string       | Yes      | A description for the token. |

Response:

If successful, returns [`201 Created`](rest/troubleshooting.md#status-codes) with the following attributes:

| Attribute               | Type    | Description |
|-------------------------|---------|-------------|
| `id`                    | integer | The unique identifier of the runner controller token. |
| `runner_controller_id`  | integer | The ID of the associated runner controller. |
| `description`           | string  | A description for the token. |
| `created_at`            | datetime| The date and time when the token was created. |
| `updated_at`            | datetime| The date and time when the token was last updated. |
| `token`                 | string  | The actual token value used for authentication. |

Example request:

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --header "Content-Type: application/json" \
    --data '{"description": "Token for runner controller"}' \
    --url "https://gitlab.example.com/api/v4/runner_controllers/:id/tokens"
```

Example response:

```json
{
    "id": 1,
    "runner_controller_id": 1,
    "description": "Token for runner controller",
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-01T00:00:00Z",
    "token": "glrct-<token>"
}
```

## Revoke a runner controller token

Revokes an existing runner controller token.

```plaintext
DELETE /runner_controllers/:id/tokens/:token_id
```

Parameters:

| Attribute          | Type         | Required | Description |
|--------------------|--------------|----------|-------------|
| `id`               | integer      | Yes      | The ID of the runner controller. |
| `token_id`         | integer      | Yes      | The ID of the runner controller token. |

If successful, it returns [`204 No Content`](rest/troubleshooting.md#status-codes).

```shell
curl --request DELETE \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/runner_controllers/:id/tokens/:token_id"
```

## Rotate a runner controller token

Rotates an existing runner controller token.

```plaintext
POST /runner_controllers/:id/tokens/:token_id/rotate
```

Parameters:

| Attribute          | Type         | Required | Description |
|--------------------|--------------|----------|-------------|
| `id`               | integer      | Yes      | The ID of the runner controller. |
| `token_id`         | integer      | Yes      | The ID of the runner controller token. |

Response:

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) with the following attributes:

| Attribute               | Type    | Description |
|-------------------------|---------|-------------|
| `id`                    | integer | The unique identifier of the runner controller token. |
| `runner_controller_id`  | integer | The ID of the associated runner controller. |
| `description`           | string  | A description for the token. |
| `created_at`            | datetime| The date and time when the token was created. |
| `updated_at`            | datetime| The date and time when the token was last updated. |
| `token`                 | string  | The actual token value used for authentication. |

Example request:

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/runner_controllers/:id/tokens/:token_id/rotate"
```

Example response:

```json
{
    "id": 1,
    "runner_controller_id": 1,
    "description": "Token for runner controller",
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-01T00:00:00Z",
    "token": "glrct-<token>"
}
```

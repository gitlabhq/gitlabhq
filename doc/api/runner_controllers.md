---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Runner controllers API
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218229) in GitLab 18.9.

{{< /history >}}

The runner controllers API allows you to manage runner controllers for GitLab Runner job
orchestration and admission control. This API provides endpoints to create, read, update,
and delete runner controllers.

Prerequisites:

- You must have administrator access to the GitLab instance.

## List runner controllers

List all runner controllers.

```plaintext
GET /runner_controllers
```

Response:

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) with the following response attributes:

| Attribute          | Type         | Description |
|--------------------|--------------|-------------|
| `id`               | integer      | The unique identifier of the runner controller. |
| `description`      | string       | A description for the runner controller. |
| `enabled`          | boolean      | Indicates whether the runner controller is enabled. |
| `created_at`       | datetime     | The date and time when the runner controller was created. |
| `updated_at`       | datetime     | The date and time when the runner controller was last updated. |

Example request:

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers"
```

Example response:

```json
[
    {
        "id": 1,
        "description": "Runner controller",
        "enabled": true,
        "created_at": "2026-01-01T00:00:00Z",
        "updated_at": "2026-01-02T00:00:00Z"
    },
    {
        "id": 2,
        "description": "Another runner controller",
        "enabled": false,
        "created_at": "2026-01-03T00:00:00Z",
        "updated_at": "2026-01-04T00:00:00Z"
    }
]
```

## Get a single runner controller

Retrieve details of a specific runner controller by its ID.

```plaintext
GET /runner_controllers/:id
```

Response:

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) with the following response attributes:

| Attribute          | Type         | Description |
|--------------------|--------------|-------------|
| `id`               | integer      | The unique identifier of the runner controller. |
| `description`      | string       | A description for the runner controller. |
| `enabled`          | boolean      | Indicates whether the runner controller is enabled. |
| `created_at`       | datetime     | The date and time when the runner controller was created. |
| `updated_at`       | datetime     | The date and time when the runner controller was last updated. |

Example request:

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/1"
```

Example response:

```json
{
    "id": 1,
    "description": "Runner controller",
    "enabled": true,
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-02T00:00:00Z"
}
```

## Register a runner controller

Register a new runner controller.

```plaintext
POST /runner_controllers
```

Supported attributes:

| Attribute          | Type         | Required | Description |
|--------------------|--------------|----------|-------------|
| `description`      | string       | No       | A description for the runner controller. |
| `enabled`          | boolean      | No       | Indicates whether the runner controller is enabled. |

Response:

If successful, returns [`201 Created`](rest/troubleshooting.md#status-codes) with the following response attributes:

| Attribute          | Type         | Description |
|--------------------|--------------|-------------|
| `id`               | integer      | The unique identifier of the runner controller. |
| `description`      | string       | A description for the runner controller. |
| `enabled`          | boolean      | Indicates whether the runner controller is enabled. |
| `created_at`       | datetime     | The date and time when the runner controller was created. |
| `updated_at`       | datetime     | The date and time when the runner controller was last updated. |

Example request:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"description": "New runner controller"}' \
     --url "https://gitlab.example.com/api/v4/runner_controllers"
```

Example response:

```json
{
    "id": 3,
    "description": "New runner controller",
    "enabled": false,
    "created_at": "2026-01-05T00:00:00Z",
    "updated_at": "2026-01-05T00:00:00Z"
}
```

## Update a runner controller

Update the details of an existing runner controller by its ID.

```plaintext
PUT /runner_controllers/:id
```

Supported attributes:

| Attribute          | Type         | Required | Description |
|--------------------|--------------|----------|-------------|
| `description`      | string       | No       | A description for the runner controller. |
| `enabled`          | boolean      | No       | Indicates whether the runner controller is enabled. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) with the following response attributes:

| Attribute          | Type         | Description |
|--------------------|--------------|-------------|
| `id`               | integer      | The unique identifier of the runner controller. |
| `description`      | string       | A description for the runner controller. |
| `enabled`          | boolean      | Indicates whether the runner controller is enabled. |
| `created_at`       | datetime     | The date and time when the runner controller was created. |
| `updated_at`       | datetime     | The date and time when the runner controller was last updated. |

Example request:

```shell
curl --request PUT \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"description": "Updated runner controller", "enabled": true}' \
     --url "https://gitlab.example.com/api/v4/runner_controllers/3"
```

Example response:

```json
{
    "id": 3,
    "description": "Updated runner controller",
    "enabled": true,
    "created_at": "2026-01-05T00:00:00Z",
    "updated_at": "2026-01-06T00:00:00Z"
}
```

## Delete a runner controller

Delete a specific runner controller by its ID.

```plaintext
DELETE /runner_controllers/:id
```

If successful, returns [`204 No Content`](rest/troubleshooting.md#status-codes).

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/3"
```

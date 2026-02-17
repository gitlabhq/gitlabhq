---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Runner controllers API
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

The runner controllers API allows you to manage runner controllers for CI/CD job admission
control. Runner controllers connect to the job router and evaluate jobs against custom
policies, deciding whether to admit or reject them. This API provides endpoints to create,
read, update, and delete runner controllers.

Prerequisites:

- You must have administrator access to the GitLab instance.

## List all runner controllers

Lists all runner controllers.

```plaintext
GET /runner_controllers
```

Response:

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) with the following response attributes:

| Attribute          | Type         | Description |
|--------------------|--------------|-------------|
| `id`               | integer      | The unique identifier of the runner controller. |
| `description`      | string       | A description for the runner controller. |
| `state`            | string       | The state of the runner controller. Valid values are `disabled` (default), `enabled`, or `dry_run`. |
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
        "state": "enabled",
        "created_at": "2026-01-01T00:00:00Z",
        "updated_at": "2026-01-02T00:00:00Z"
    },
    {
        "id": 2,
        "description": "Another runner controller",
        "state": "disabled",
        "created_at": "2026-01-03T00:00:00Z",
        "updated_at": "2026-01-04T00:00:00Z"
    }
]
```

## Retrieve a single runner controller

Retrieves details of a specific runner controller by its ID.

```plaintext
GET /runner_controllers/:id
```

Response:

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) with the following response attributes:

| Attribute          | Type         | Description |
|--------------------|--------------|-------------|
| `id`               | integer      | The unique identifier of the runner controller. |
| `description`      | string       | A description for the runner controller. |
| `state`            | string       | The state of the runner controller. Valid values are `disabled` (default), `enabled`, or `dry_run`. |
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
    "state": "enabled",
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-02T00:00:00Z"
}
```

## Register a runner controller

Registers a new runner controller.

```plaintext
POST /runner_controllers
```

Supported attributes:

| Attribute          | Type         | Required | Description |
|--------------------|--------------|----------|-------------|
| `description`      | string       | No       | A description for the runner controller. |
| `state`            | string       | No       | The state of the runner controller. Valid values are `disabled` (default), `enabled`, or `dry_run`. |

Response:

If successful, returns [`201 Created`](rest/troubleshooting.md#status-codes) with the following response attributes:

| Attribute          | Type         | Description |
|--------------------|--------------|-------------|
| `id`               | integer      | The unique identifier of the runner controller. |
| `description`      | string       | A description for the runner controller. |
| `state`            | string       | The state of the runner controller. Valid values are `disabled` (default), `enabled`, or `dry_run`. |
| `created_at`       | datetime     | The date and time when the runner controller was created. |
| `updated_at`       | datetime     | The date and time when the runner controller was last updated. |

Example request:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"description": "New runner controller", "state": "dry_run"}' \
     --url "https://gitlab.example.com/api/v4/runner_controllers"
```

Example response:

```json
{
    "id": 3,
    "description": "New runner controller",
    "state": "dry_run",
    "created_at": "2026-01-05T00:00:00Z",
    "updated_at": "2026-01-05T00:00:00Z"
}
```

## Update a runner controller

Updates the details of an existing runner controller by its ID.

```plaintext
PUT /runner_controllers/:id
```

Supported attributes:

| Attribute          | Type         | Required | Description |
|--------------------|--------------|----------|-------------|
| `description`      | string       | No       | A description for the runner controller. |
| `state`            | string       | No       | The state of the runner controller. Valid values are `disabled` (default), `enabled`, or `dry_run`. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) with the following response attributes:

| Attribute          | Type         | Description |
|--------------------|--------------|-------------|
| `id`               | integer      | The unique identifier of the runner controller. |
| `description`      | string       | A description for the runner controller. |
| `state`            | string       | The state of the runner controller. Valid values are `disabled` (default), `enabled`, or `dry_run`. |
| `created_at`       | datetime     | The date and time when the runner controller was created. |
| `updated_at`       | datetime     | The date and time when the runner controller was last updated. |

Example request:

```shell
curl --request PUT \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"description": "Updated runner controller", "state": "enabled"}' \
     --url "https://gitlab.example.com/api/v4/runner_controllers/3"
```

Example response:

```json
{
    "id": 3,
    "description": "Updated runner controller",
    "state": "enabled",
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

## Runner controller scopes

Runner controller scopes define which jobs a runner controller evaluates for admission control.
A runner controller must have at least one scope to receive admission requests. Without a scope,
the controller remains inactive even when its state is `enabled` or `dry_run`.

Instance scope: The runner controller evaluates jobs for all runners in the GitLab instance.

> [!note]
> Only instance scoping is available. Runner scoping and additional
> scope types are proposed in [issue 586419](https://gitlab.com/gitlab-org/gitlab/-/issues/586419).

### List all scopes for a runner controller

Lists all scopes configured for a specific runner controller:

```plaintext
GET /runner_controllers/:id/scopes
```

Supported attributes:

| Attribute | Type    | Required | Description                              |
|-----------|---------|----------|------------------------------------------|
| `id`      | integer | Yes      | The ID of the runner controller.         |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                              | Type         | Description                                               |
|----------------------------------------|--------------|-----------------------------------------------------------|
| `instance_level_scopings`              | object array | List of instance-level scoping for the runner controller. |
| `instance_level_scopings[].created_at` | datetime     | The date and time when the scoping was created.           |
| `instance_level_scopings[].updated_at` | datetime     | The date and time when the scoping was last updated.      |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/1/scopes"
```

Example response:

```json
{
    "instance_level_scopings": [
        {
            "created_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-01-01T00:00:00Z"
        }
    ]
}
```

### Add instance scope

Adds an instance scope to a runner controller. When added, the runner controller
evaluates jobs for all runners in the GitLab instance.

A runner controller can have only one instance scope. If an instance scope
already exists, this endpoint returns an error.

```plaintext
POST /runner_controllers/:id/scopes/instance
```

Supported attributes:

| Attribute | Type    | Required | Description                              |
|-----------|---------|----------|------------------------------------------|
| `id`      | integer | Yes      | The ID of the runner controller.         |

If successful, returns [`201 Created`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute               | Type     | Description                                          |
|-------------------------|----------|------------------------------------------------------|
| `created_at`            | datetime | The date and time when the scoping was created.      |
| `updated_at`            | datetime | The date and time when the scoping was last updated. |

Example request:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/1/scopes/instance"
```

Example response:

```json
{
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-01T00:00:00Z"
}
```

### Remove instance scope

Removes an instance scope from a runner controller.

```plaintext
DELETE /runner_controllers/:id/scopes/instance
```

Supported attributes:

| Attribute     | Type    | Required | Description                                          |
|---------------|---------|----------|------------------------------------------------------|
| `id`          | integer | Yes      | The ID of the runner controller.                     |

If successful, returns [`204 No Content`](rest/troubleshooting.md#status-codes).

Example request:

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/1/scopes/instance"
```

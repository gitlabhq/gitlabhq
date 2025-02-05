---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Pipeline schedules API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can read more about [pipeline schedules](../ci/pipelines/schedules.md).

## Get all pipeline schedules

Get a list of the pipeline schedules of a project.

```plaintext
GET /projects/:id/pipeline_schedules
```

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `scope`   | string         | No       | The scope of pipeline schedules, must be one of: `active`, `inactive` |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules"
```

```json
[
    {
        "id": 13,
        "description": "Test schedule pipeline",
        "ref": "refs/heads/main",
        "cron": "* * * * *",
        "cron_timezone": "Asia/Tokyo",
        "next_run_at": "2017-05-19T13:41:00.000Z",
        "active": true,
        "created_at": "2017-05-19T13:31:08.849Z",
        "updated_at": "2017-05-19T13:40:17.727Z",
        "owner": {
            "name": "Administrator",
            "username": "root",
            "id": 1,
            "state": "active",
            "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
            "web_url": "https://gitlab.example.com/root"
        }
    }
]
```

## Get a single pipeline schedule

Get the pipeline schedule of a project.

```plaintext
GET /projects/:id/pipeline_schedules/:pipeline_schedule_id
```

| Attribute              | Type           | Required | Description |
|------------------------|----------------|----------|-------------|
| `id`                   | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `pipeline_schedule_id` | integer        | Yes      | The pipeline schedule ID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13"
```

```json
{
    "id": 13,
    "description": "Test schedule pipeline",
    "ref": "refs/heads/main",
    "cron": "* * * * *",
    "cron_timezone": "Asia/Tokyo",
    "next_run_at": "2017-05-19T13:41:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:31:08.849Z",
    "updated_at": "2017-05-19T13:40:17.727Z",
    "last_pipeline": {
        "id": 332,
        "sha": "0e788619d0b5ec17388dffb973ecd505946156db",
        "ref": "refs/heads/main",
        "status": "pending"
    },
    "owner": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/root"
    },
    "variables": [
        {
            "key": "TEST_VARIABLE_1",
            "variable_type": "env_var",
            "value": "TEST_1",
            "raw": false
        }
    ]
}
```

## Get all pipelines triggered by a pipeline schedule

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/368566) in GitLab 15.3.

Get all pipelines triggered by a pipeline schedule in a project.

```plaintext
GET /projects/:id/pipeline_schedules/:pipeline_schedule_id/pipelines
```

Supported attributes:

| Attribute              | Type           | Required | Description |
|------------------------|----------------|----------|-------------|
| `id`                   | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `pipeline_schedule_id` | integer        | Yes      | The pipeline schedule ID. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/pipelines"
```

Example response:

```json
[
  {
    "id": 47,
    "iid": 12,
    "project_id": 29,
    "status": "pending",
    "source": "scheduled",
    "ref": "new-pipeline",
    "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
    "web_url": "https://example.com/foo/bar/pipelines/47",
    "created_at": "2016-08-11T11:28:34.085Z",
    "updated_at": "2016-08-11T11:32:35.169Z"
  },
  {
    "id": 48,
    "iid": 13,
    "project_id": 29,
    "status": "pending",
    "source": "scheduled",
    "ref": "new-pipeline",
    "sha": "eb94b618fb5865b26e80fdd8ae531b7a63ad851a",
    "web_url": "https://example.com/foo/bar/pipelines/48",
    "created_at": "2016-08-12T10:06:04.561Z",
    "updated_at": "2016-08-12T10:09:56.223Z"
  }
]
```

## Create a new pipeline schedule

Create a new pipeline schedule of a project.

```plaintext
POST /projects/:id/pipeline_schedules
```

| Attribute       | Type           | Required | Description                                                                                                                                                                                                                                                                           |
|-----------------|----------------|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `cron`          | string         | Yes      | The [cron](https://en.wikipedia.org/wiki/Cron) schedule, for example: `0 1 * * *`.                                                                                                                                                                                                    |
| `description`   | string         | Yes      | The description of the pipeline schedule.                                                                                                                                                                                                                                             |
| `id`            | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).                                                                                                                                                                                                  |
| `ref`           | string         | Yes      | The branch or tag name that is triggered. Both the short (e.g. `main`) and full (e.g. `refs/heads/main` or `refs/tags/main`) ref versions are accepted. If a short version is provided, it is automatically expanded to the full ref version but, if the ref is [ambiguous](../ci/pipelines/schedules.md#ambiguous-refs), it will be rejected |
| `active`        | boolean        | No       | The activation of pipeline schedule. If false is set, the pipeline schedule is initially deactivated (default: `true`).                                                                                                                                                               |
| `cron_timezone` | string         | No       | The time zone supported by `ActiveSupport::TimeZone`, for example: `Pacific Time (US & Canada)` (default: `UTC`).                                                                                                                                                                     |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --form description="Build packages" --form ref="main" --form cron="0 1 * * 5" --form cron_timezone="UTC" \
     --form active="true" "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules"
```

```json
{
    "id": 14,
    "description": "Build packages",
    "ref": "refs/heads/main",
    "cron": "0 1 * * 5",
    "cron_timezone": "UTC",
    "next_run_at": "2017-05-26T01:00:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:43:08.169Z",
    "updated_at": "2017-05-19T13:43:08.169Z",
    "last_pipeline": null,
    "owner": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/root"
    }
}
```

## Edit a pipeline schedule

Updates the pipeline schedule of a project. After the update is done, it is rescheduled automatically.

```plaintext
PUT /projects/:id/pipeline_schedules/:pipeline_schedule_id
```

| Attribute              | Type           | Required | Description                                                                                                                                                                                                                                                                                                                                   |
|------------------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`                   | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).                                                                                                                                                                                                                                                          |
| `pipeline_schedule_id` | integer        | Yes      | The pipeline schedule ID.                                                                                                                                                                                                                                                                                                                     |
| `active`               | boolean        | No       | The activation of pipeline schedule. If false is set, the pipeline schedule is initially deactivated.                                                                                                                                                                                                                                         |
| `cron_timezone`        | string         | No       | The time zone supported by `ActiveSupport::TimeZone` (for example `Pacific Time (US & Canada)`), or `TZInfo::Timezone` (for example `America/Los_Angeles`).                                                                                                                                                                                   |
| `cron`                 | string         | No       | The [cron](https://en.wikipedia.org/wiki/Cron) schedule, for example: `0 1 * * *`.                                                                                                                                                                                                                                                            |
| `description`          | string         | No       | The description of the pipeline schedule.                                                                                                                                                                                                                                                                                                     |
| `ref`                  | string         | No       | The branch or tag name that is triggered. Both the short (e.g. `main`) and full (e.g. `refs/heads/main` or `refs/tags/main`) ref versions are accepted. If a short version is provided, it is automatically expanded to the full ref version but, if the ref is [ambiguous](../ci/pipelines/schedules.md#ambiguous-refs), it will be rejected |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --form cron="0 2 * * *" "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13"
```

```json
{
    "id": 13,
    "description": "Test schedule pipeline",
    "ref": "refs/heads/main",
    "cron": "0 2 * * *",
    "cron_timezone": "Asia/Tokyo",
    "next_run_at": "2017-05-19T17:00:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:31:08.849Z",
    "updated_at": "2017-05-19T13:44:16.135Z",
    "last_pipeline": {
        "id": 332,
        "sha": "0e788619d0b5ec17388dffb973ecd505946156db",
        "ref": "refs/heads/main",
        "status": "pending"
    },
    "owner": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/root"
    }
}
```

## Take ownership of a pipeline schedule

Update the owner of the pipeline schedule of a project.

```plaintext
POST /projects/:id/pipeline_schedules/:pipeline_schedule_id/take_ownership
```

| Attribute              | Type           | Required | Description |
|------------------------|----------------|----------|-------------|
| `id`                   | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `pipeline_schedule_id` | integer        | Yes      | The pipeline schedule ID |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/take_ownership"
```

```json
{
    "id": 13,
    "description": "Test schedule pipeline",
    "ref": "refs/heads/main",
    "cron": "0 2 * * *",
    "cron_timezone": "Asia/Tokyo",
    "next_run_at": "2017-05-19T17:00:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:31:08.849Z",
    "updated_at": "2017-05-19T13:46:37.468Z",
    "last_pipeline": {
        "id": 332,
        "sha": "0e788619d0b5ec17388dffb973ecd505946156db",
        "ref": "refs/heads/main",
        "status": "pending"
    },
    "owner": {
        "name": "shinya",
        "username": "maeda",
        "id": 50,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/8ca0a796a679c292e3a11da50f99e801?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/maeda"
    }
}
```

## Delete a pipeline schedule

Delete the pipeline schedule of a project.

```plaintext
DELETE /projects/:id/pipeline_schedules/:pipeline_schedule_id
```

| Attribute              | Type           | Required | Description |
|------------------------|----------------|----------|-------------|
| `id`                   | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `pipeline_schedule_id` | integer        | Yes      | The pipeline schedule ID |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13"
```

```json
{
    "id": 13,
    "description": "Test schedule pipeline",
    "ref": "refs/heads/main",
    "cron": "0 2 * * *",
    "cron_timezone": "Asia/Tokyo",
    "next_run_at": "2017-05-19T17:00:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:31:08.849Z",
    "updated_at": "2017-05-19T13:46:37.468Z",
    "last_pipeline": {
        "id": 332,
        "sha": "0e788619d0b5ec17388dffb973ecd505946156db",
        "ref": "refs/heads/main",
        "status": "pending"
    },
    "owner": {
        "name": "shinya",
        "username": "maeda",
        "id": 50,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/8ca0a796a679c292e3a11da50f99e801?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/maeda"
    }
}
```

## Run a scheduled pipeline immediately

Trigger a new scheduled pipeline, which runs immediately. The next scheduled run
of this pipeline is not affected.

```plaintext
POST /projects/:id/pipeline_schedules/:pipeline_schedule_id/play
```

| Attribute              | Type           | Required | Description |
|------------------------|----------------|----------|-------------|
| `id`                   | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `pipeline_schedule_id` | integer        | Yes      | The pipeline schedule ID |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/42/pipeline_schedules/1/play"
```

Example response:

```json
{
  "message": "201 Created"
}
```

## Pipeline schedule variables

## Create a new pipeline schedule variable

Create a new variable of a pipeline schedule.

```plaintext
POST /projects/:id/pipeline_schedules/:pipeline_schedule_id/variables
```

| Attribute              | Type           | Required | Description |
|------------------------|----------------|----------|-------------|
| `id`                   | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `key`                  | string         | Yes      | The `key` of a variable; must have no more than 255 characters; only `A-Z`, `a-z`, `0-9`, and `_` are allowed |
| `pipeline_schedule_id` | integer        | Yes      | The pipeline schedule ID |
| `value`                | string         | Yes      | The `value` of a variable |
| `variable_type`        | string         | No       | The type of a variable. Available types are: `env_var` (default) and `file` |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --form "key=NEW_VARIABLE" \
     --form "value=new value" "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/variables"
```

```json
{
    "key": "NEW_VARIABLE",
    "variable_type": "env_var",
    "value": "new value"
}
```

## Edit a pipeline schedule variable

Updates the variable of a pipeline schedule.

```plaintext
PUT /projects/:id/pipeline_schedules/:pipeline_schedule_id/variables/:key
```

| Attribute              | Type           | Required | Description |
|------------------------|----------------|----------|-------------|
| `id`                   | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `key`                  | string         | Yes      | The `key` of a variable |
| `pipeline_schedule_id` | integer        | Yes      | The pipeline schedule ID |
| `value`                | string         | Yes      | The `value` of a variable |
| `variable_type`        | string         | No       | The type of a variable. Available types are: `env_var` (default) and `file` |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "value=updated value" \
     "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/variables/NEW_VARIABLE"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "updated value",
    "variable_type": "env_var"
}
```

## Delete a pipeline schedule variable

Delete the variable of a pipeline schedule.

```plaintext
DELETE /projects/:id/pipeline_schedules/:pipeline_schedule_id/variables/:key
```

| Attribute              | Type           | Required | Description |
|------------------------|----------------|----------|-------------|
| `id`                   | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `key`                  | string         | Yes      | The `key` of a variable |
| `pipeline_schedule_id` | integer        | Yes      | The pipeline schedule ID |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/variables/NEW_VARIABLE"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "updated value"
}
```

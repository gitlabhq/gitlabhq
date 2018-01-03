# Pipeline schedules

You can read more about [pipeline schedules](../user/project/pipelines/schedules.md).

## Get all pipeline schedules

Get a list of the pipeline schedules of a project.

```
GET /projects/:id/pipeline_schedules
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `scope`   | string  | no       | The scope of pipeline schedules, one of: `active`, `inactive` |

```sh
curl --header "PRIVATE-TOKEN: k5ESFgWY2Qf5xEvDcFxZ" "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules"
```

```json
[
    {
        "id": 13,
        "description": "Test schedule pipeline",
        "ref": "master",
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

```
GET /projects/:id/pipeline_schedules/:pipeline_schedule_id
```

| Attribute    | Type    | required | Description              |
|--------------|---------|----------|--------------------------|
| `id`         | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user      |
| `pipeline_schedule_id` | integer | yes      | The pipeline schedule id           |

```sh
curl --header "PRIVATE-TOKEN: k5ESFgWY2Qf5xEvDcFxZ" "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13"
```

```json
{
    "id": 13,
    "description": "Test schedule pipeline",
    "ref": "master",
    "cron": "* * * * *",
    "cron_timezone": "Asia/Tokyo",
    "next_run_at": "2017-05-19T13:41:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:31:08.849Z",
    "updated_at": "2017-05-19T13:40:17.727Z",
    "last_pipeline": {
        "id": 332,
        "sha": "0e788619d0b5ec17388dffb973ecd505946156db",
        "ref": "master",
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
            "value": "TEST_1"
        }
    ]
}
```

## Create a new pipeline schedule

Create a new pipeline schedule of a project.

```
POST /projects/:id/pipeline_schedules
```

| Attribute     | Type    | required | Description              |
|---------------|---------|----------|--------------------------|
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user      |
| `description` | string  | yes      | The description of pipeline schedule         |
| `ref` | string  | yes      | The branch/tag name will be triggered         |
| `cron ` | string  | yes      | The cron (e.g. `0 1 * * *`) ([Cron syntax](https://en.wikipedia.org/wiki/Cron))       |
| `cron_timezone ` | string  | no      | The timezone supproted by `ActiveSupport::TimeZone` (e.g. `Pacific Time (US & Canada)`) (default: `'UTC'`)     |
| `active ` | boolean  | no      | The activation of pipeline schedule. If false is set, the pipeline schedule will deactivated initially (default: `true`) |

```sh
curl --request POST --header "PRIVATE-TOKEN: k5ESFgWY2Qf5xEvDcFxZ" --form description="Build packages" --form ref="master" --form cron="0 1 * * 5" --form cron_timezone="UTC" --form active="true" "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules"
```

```json
{
    "id": 14,
    "description": "Build packages",
    "ref": "master",
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

Updates the pipeline schedule  of a project. Once the update is done, it will be rescheduled automatically.

```
PUT /projects/:id/pipeline_schedules/:pipeline_schedule_id
```

| Attribute     | Type    | required | Description              |
|---------------|---------|----------|--------------------------|
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user      |
| `pipeline_schedule_id`  | integer | yes      | The pipeline schedule id           |
| `description` | string  | no      | The description of pipeline schedule         |
| `ref` | string  | no      | The branch/tag name will be triggered         |
| `cron ` | string  | no      | The cron (e.g. `0 1 * * *`) ([Cron syntax](https://en.wikipedia.org/wiki/Cron))       |
| `cron_timezone ` | string  | no      | The timezone supproted by `ActiveSupport::TimeZone` (e.g. `Pacific Time (US & Canada)`) or `TZInfo::Timezone` (e.g. `America/Los_Angeles`)      |
| `active ` | boolean  | no      | The activation of pipeline schedule. If false is set, the pipeline schedule will deactivated initially. |

```sh
curl --request PUT --header "PRIVATE-TOKEN: k5ESFgWY2Qf5xEvDcFxZ" --form cron="0 2 * * *" "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13"
```

```json
{
    "id": 13,
    "description": "Test schedule pipeline",
    "ref": "master",
    "cron": "0 2 * * *",
    "cron_timezone": "Asia/Tokyo",
    "next_run_at": "2017-05-19T17:00:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:31:08.849Z",
    "updated_at": "2017-05-19T13:44:16.135Z",
    "last_pipeline": {
        "id": 332,
        "sha": "0e788619d0b5ec17388dffb973ecd505946156db",
        "ref": "master",
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

```
POST /projects/:id/pipeline_schedules/:pipeline_schedule_id/take_ownership
```

| Attribute     | Type    | required | Description              |
|---------------|---------|----------|--------------------------|
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user      |
| `pipeline_schedule_id`  | integer | yes      | The pipeline schedule id           |

```sh
curl --request POST --header "PRIVATE-TOKEN: hf2CvZXB9w8Uc5pZKpSB" "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/take_ownership"
```

```json
{
    "id": 13,
    "description": "Test schedule pipeline",
    "ref": "master",
    "cron": "0 2 * * *",
    "cron_timezone": "Asia/Tokyo",
    "next_run_at": "2017-05-19T17:00:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:31:08.849Z",
    "updated_at": "2017-05-19T13:46:37.468Z",
    "last_pipeline": {
        "id": 332,
        "sha": "0e788619d0b5ec17388dffb973ecd505946156db",
        "ref": "master",
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

```
DELETE /projects/:id/pipeline_schedules/:pipeline_schedule_id
```

| Attribute      | Type    | required | Description              |
|----------------|---------|----------|--------------------------|
| `id`           | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user      |
| `pipeline_schedule_id`   | integer | yes      | The pipeline schedule id           |

```sh
curl --request DELETE --header "PRIVATE-TOKEN: k5ESFgWY2Qf5xEvDcFxZ" "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13"
```

```json
{
    "id": 13,
    "description": "Test schedule pipeline",
    "ref": "master",
    "cron": "0 2 * * *",
    "cron_timezone": "Asia/Tokyo",
    "next_run_at": "2017-05-19T17:00:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:31:08.849Z",
    "updated_at": "2017-05-19T13:46:37.468Z",
    "last_pipeline": {
        "id": 332,
        "sha": "0e788619d0b5ec17388dffb973ecd505946156db",
        "ref": "master",
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

## Pipeline schedule variable

> [Introduced][ce-34518] in GitLab 10.0.

## Create a new pipeline schedule variable

Create a new variable of a pipeline schedule.

```
POST /projects/:id/pipeline_schedules/:pipeline_schedule_id/variables
```

| Attribute              | Type           | required | Description              |
|------------------------|----------------|----------|--------------------------|
| `id`                   | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user      |
| `pipeline_schedule_id` | integer        | yes      | The pipeline schedule id |
| `key`                  | string         | yes      | The `key` of a variable; must have no more than 255 characters; only `A-Z`, `a-z`, `0-9`, and `_` are allowed |
| `value`                | string         | yes      | The `value` of a variable |

```sh
curl --request POST --header "PRIVATE-TOKEN: k5ESFgWY2Qf5xEvDcFxZ" --form "key=NEW_VARIABLE" --form "value=new value" "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/variables"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "new value"
}
```

## Edit a pipeline schedule variable

Updates the variable of a pipeline schedule.

```
PUT /projects/:id/pipeline_schedules/:pipeline_schedule_id/variables/:key
```

| Attribute              | Type           | required | Description              |
|------------------------|----------------|----------|--------------------------|
| `id`                   | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user      |
| `pipeline_schedule_id` | integer        | yes      | The pipeline schedule id |
| `key`                  | string         | yes      | The `key` of a variable   |
| `value`                | string         | yes      | The `value` of a variable |

```sh
curl --request PUT --header "PRIVATE-TOKEN: k5ESFgWY2Qf5xEvDcFxZ" --form "value=updated value" "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/variables/NEW_VARIABLE"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "updated value"
}
```

## Delete a pipeline schedule variable

Delete the variable of a pipeline schedule.

```
DELETE /projects/:id/pipeline_schedules/:pipeline_schedule_id/variables/:key
```

| Attribute              | Type           | required | Description              |
|------------------------|----------------|----------|--------------------------|
| `id`                   | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user      |
| `pipeline_schedule_id` | integer        | yes      | The pipeline schedule id |
| `key`                  | string         | yes      | The `key` of a variable |

```sh
curl --request DELETE --header "PRIVATE-TOKEN: k5ESFgWY2Qf5xEvDcFxZ" "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/variables/NEW_VARIABLE"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "updated value"
}
```

[ce-34518]: https://gitlab.com/gitlab-org/gitlab-ce/issues/34518
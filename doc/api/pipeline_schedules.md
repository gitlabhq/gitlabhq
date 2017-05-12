# Pipeline schedules

You can read more about [pipeline schedules](../ci/pipeline_schedules.md).

## List Pipeline schedules

Get a list of pipeline schedules.

```
GET /projects/:id/pipeline_schedules
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |

```
curl --header "PRIVATE-TOKEN: k5ESFgWY2Qf5xEvDcFxZ" "http://192.168.10.5:3000/api/v4/projects/28/pipeline_schedules"
```

```json
[
    {
        "id": 11,
        "description": "Acceptance Test",
        "ref": "master",
        "cron": "0 4 * * *",
        "cron_timezone": "America/Los_Angeles",
        "next_run_at": "2017-05-13T11:00:00.000Z",
        "active": true,
        "created_at": "2017-05-12T13:10:34.497Z",
        "updated_at": "2017-05-12T13:10:34.497Z",
        "deleted_at": null,
        "owner": {
            "name": "Administrator",
            "username": "root",
            "id": 1,
            "state": "active",
            "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
            "web_url": "http://192.168.10.5:3000/root"
        }
    }
]
```

## Single pipeline schedule

Get a single pipeline schedule.

```
GET /projects/:id/pipeline_schedules/:pipeline_schedule_id
```

| Attribute    | Type    | required | Description              |
|--------------|---------|----------|--------------------------|
| `id`         | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user      |
| `pipeline_schedule_id` | integer | yes      | The pipeline schedule id           |

```
curl --header "PRIVATE-TOKEN: k5ESFgWY2Qf5xEvDcFxZ" "http://192.168.10.5:3000/api/v4/projects/28/pipeline_schedules/11"
```

```json
{
    "id": 11,
    "description": "Acceptance Test",
    "ref": "master",
    "cron": "0 4 * * *",
    "cron_timezone": "America/Los_Angeles",
    "next_run_at": "2017-05-13T11:00:00.000Z",
    "active": true,
    "created_at": "2017-05-12T13:10:34.497Z",
    "updated_at": "2017-05-12T13:10:34.497Z",
    "deleted_at": null,
    "owner": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "http://192.168.10.5:3000/root"
    }
}
```

## New pipeline schedule

Creates a new pipeline schedule.

```
POST /projects/:id/pipeline_schedules
```

| Attribute     | Type    | required | Description              |
|---------------|---------|----------|--------------------------|
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user      |
| `description` | string  | yes      | The description of pipeline schedule         |
| `ref` | string  | yes      | The branch/tag name will be triggered         |
| `cron ` | string  | yes      | The cron (e.g. `0 1 * * *`) ([Cron syntax](https://en.wikipedia.org/wiki/Cron))       |
| `cron_timezone ` | string  | yes      | The timezone supproted by `ActiveSupport::TimeZone` (e.g. `Pacific Time (US & Canada)`) or `TZInfo::Timezone` (e.g. `America/Los_Angeles`)      |
| `active ` | boolean  | yes      | The activation of pipeline schedule. If false is set, the pipeline schedule will deactivated initially. |

```
curl --request POST --header "PRIVATE-TOKEN: k5ESFgWY2Qf5xEvDcFxZ" --form description="Build packages" --form ref="master" --form cron="0 1 * * 5" --form cron_timezone="UTC" --form active="true" "http://192.168.10.5:3000/api/v4/projects/28/pipeline_schedules"
```

```json
{
    "id": 12,
    "description": "Build packages",
    "ref": "master",
    "cron": "0 1 * * 5",
    "cron_timezone": "UTC",
    "next_run_at": "2017-05-19T01:00:00.000Z",
    "active": true,
    "created_at": "2017-05-12T13:18:58.879Z",
    "updated_at": "2017-05-12T13:18:58.879Z",
    "deleted_at": null,
    "owner": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "http://192.168.10.5:3000/root"
    }
}
```

## Edit pipeline schedule

Updates an existing pipeline schedule. Once the update is done, it will be rescheduled automatically.

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

```
curl --request PUT --header "PRIVATE-TOKEN: k5ESFgWY2Qf5xEvDcFxZ" --form cron="0 2 * * *" "http://192.168.10.5:3000/api/v4/projects/28/pipeline_schedules/11"
```

```json
{
    "id": 11,
    "description": "Acceptance Test",
    "ref": "master",
    "cron": "0 2 * * *",
    "cron_timezone": "America/Los_Angeles",
    "next_run_at": "2017-05-13T09:00:00.000Z",
    "active": true,
    "created_at": "2017-05-12T13:10:34.497Z",
    "updated_at": "2017-05-12T13:22:07.798Z",
    "deleted_at": null,
    "owner": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "http://192.168.10.5:3000/root"
    }
}
```

## Take ownership of a pipeline schedule

Update an owner of a pipeline schedule.

```
POST /projects/:id/pipeline_schedules/:pipeline_schedule_id/take_ownership
```

| Attribute     | Type    | required | Description              |
|---------------|---------|----------|--------------------------|
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user      |
| `pipeline_schedule_id`  | integer | yes      | The pipeline schedule id           |

```
curl --request POST --header "PRIVATE-TOKEN: hf2CvZXB9w8Uc5pZKpSB" "http://192.168.10.5:3000/api/v4/projects/28/pipeline_schedules/11/take_ownership"
```

```json
{
    "id": 11,
    "description": "Acceptance Test",
    "ref": "master",
    "cron": "0 2 * * *",
    "cron_timezone": "America/Los_Angeles",
    "next_run_at": "2017-05-13T09:00:00.000Z",
    "active": true,
    "created_at": "2017-05-12T13:10:34.497Z",
    "updated_at": "2017-05-12T13:26:12.191Z",
    "deleted_at": null,
    "owner": {
        "name": "shinya",
        "username": "maeda",
        "id": 50,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/8ca0a796a679c292e3a11da50f99e801?s=80&d=identicon",
        "web_url": "http://192.168.10.5:3000/maeda"
    }
}
```

## Delete a pipeline schedule

Delete a pipeline schedule.

```
DELETE /projects/:id/pipeline_schedules/:pipeline_schedule_id
```

| Attribute      | Type    | required | Description              |
|----------------|---------|----------|--------------------------|
| `id`           | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user      |
| `pipeline_schedule_id`   | integer | yes      | The pipeline schedule id           |

```
curl --request DELETE --header "PRIVATE-TOKEN: k5ESFgWY2Qf5xEvDcFxZ" "http://192.168.10.5:3000/api/v4/projects/28/pipeline_schedules/11"
```

```json
{
    "id": 11,
    "description": "Acceptance Test",
    "ref": "master",
    "cron": "0 2 * * *",
    "cron_timezone": "America/Los_Angeles",
    "next_run_at": "2017-05-13T09:00:00.000Z",
    "active": true,
    "created_at": "2017-05-12T13:10:34.497Z",
    "updated_at": "2017-05-12T13:26:12.191Z",
    "deleted_at": "2017-05-12T13:27:38.529Z",
    "owner": {
        "name": "shinya",
        "username": "maeda",
        "id": 50,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/8ca0a796a679c292e3a11da50f99e801?s=80&d=identicon",
        "web_url": "http://192.168.10.5:3000/maeda"
    }
}
```

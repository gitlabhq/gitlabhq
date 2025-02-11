---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Freeze Periods API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can use the Freeze Periods API to manipulate GitLab [Freeze Period](../user/project/releases/_index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze) entries.

## Permissions and security

Users with Reporter [permissions](../user/permissions.md) or greater can read
Freeze Period API endpoints. Only users with the Maintainer role can modify
Freeze Periods.

## List freeze periods

Paginated list of freeze periods, sorted by `created_at` in ascending order.

```plaintext
GET /projects/:id/freeze_periods
```

| Attribute     | Type           | Required | Description                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/19/freeze_periods"
```

Example response:

```json
[
   {
      "id":1,
      "freeze_start":"0 23 * * 5",
      "freeze_end":"0 8 * * 1",
      "cron_timezone":"UTC",
      "created_at":"2020-05-15T17:03:35.702Z",
      "updated_at":"2020-05-15T17:06:41.566Z"
   }
]
```

## Get a freeze period by a `freeze_period_id`

Get a freeze period for the given `freeze_period_id`.

```plaintext
GET /projects/:id/freeze_periods/:freeze_period_id
```

| Attribute     | Type           | Required | Description                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `freeze_period_id`    | integer         | yes      | The ID of the freeze period.                                     |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/19/freeze_periods/1"
```

Example response:

```json
{
   "id":1,
   "freeze_start":"0 23 * * 5",
   "freeze_end":"0 8 * * 1",
   "cron_timezone":"UTC",
   "created_at":"2020-05-15T17:03:35.702Z",
   "updated_at":"2020-05-15T17:06:41.566Z"
}
```

## Create a freeze period

Create a freeze period.

```plaintext
POST /projects/:id/freeze_periods
```

| Attribute          | Type            | Required                    | Description                                                                                                                      |
| -------------------| --------------- | --------                    | -------------------------------------------------------------------------------------------------------------------------------- |
| `id`               | integer or string  | yes                         | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).                                              |
| `freeze_start`     | string          | yes                         | Start of the freeze period in [cron](https://crontab.guru/) format.                                                              |
| `freeze_end`       | string          | yes                         | End of the freeze period in [cron](https://crontab.guru/) format.                                                                |
| `cron_timezone`    | string          | no                          | The time zone for the cron fields, defaults to UTC if not provided.                                                               |

Example request:

```shell
curl --header 'Content-Type: application/json' --header "PRIVATE-TOKEN: <your_access_token>" \
     --data '{ "freeze_start": "0 23 * * 5", "freeze_end": "0 7 * * 1", "cron_timezone": "UTC" }' \
     --request POST "https://gitlab.example.com/api/v4/projects/19/freeze_periods"
```

Example response:

```json
{
   "id":1,
   "freeze_start":"0 23 * * 5",
   "freeze_end":"0 7 * * 1",
   "cron_timezone":"UTC",
   "created_at":"2020-05-15T17:03:35.702Z",
   "updated_at":"2020-05-15T17:03:35.702Z"
}
```

## Update a freeze period

Update a freeze period for the given `freeze_period_id`.

```plaintext
PUT /projects/:id/freeze_periods/:freeze_period_id
```

| Attribute     | Type            | Required | Description                                                                                                 |
| ------------- | --------------- | -------- | ----------------------------------------------------------------------------------------------------------- |
| `id`          | integer or string  | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).                         |
| `freeze_period_id`    | integer          | yes      | The ID of the freeze period.                                                              |
| `freeze_start`     | string          | no                         | Start of the freeze period in [cron](https://crontab.guru/) format.                                                              |
| `freeze_end`       | string          | no                         | End of the freeze period in [cron](https://crontab.guru/) format.                                                                |
| `cron_timezone`    | string          | no                          | The time zone for the cron fields.                                                               |

Example request:

```shell
curl --header 'Content-Type: application/json' --header "PRIVATE-TOKEN: <your_access_token>" \
     --data '{ "freeze_end": "0 8 * * 1" }' \
     --request PUT "https://gitlab.example.com/api/v4/projects/19/freeze_periods/1"
```

Example response:

```json
{
   "id":1,
   "freeze_start":"0 23 * * 5",
   "freeze_end":"0 8 * * 1",
   "cron_timezone":"UTC",
   "created_at":"2020-05-15T17:03:35.702Z",
   "updated_at":"2020-05-15T17:06:41.566Z"
}
```

## Delete a freeze period

Delete a freeze period for the given `freeze_period_id`.

```plaintext
DELETE /projects/:id/freeze_periods/:freeze_period_id
```

| Attribute     | Type           | Required | Description                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `freeze_period_id`    | integer         | yes      | The ID of the freeze period.                                     |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/19/freeze_periods/1"

```

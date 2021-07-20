---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: concepts, howto
---

# Freeze Periods API

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/29382) in GitLab 13.0.

You can use the Freeze Periods API to manipulate GitLab [Freeze Period](../user/project/releases/index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze) entries.

## Permissions and security

Only users with Maintainer [permissions](../user/permissions.md) can
interact with the Freeze Period API endpoints.

## List Freeze Periods

Paginated list of Freeze Periods, sorted by `created_at` in ascending order.

```plaintext
GET /projects/:id/freeze_periods
```

| Attribute     | Type           | Required | Description                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |

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

## Get a Freeze Period by a `freeze_period_id`

Get a Freeze Period for the given `freeze_period_id`.

```plaintext
GET /projects/:id/freeze_periods/:freeze_period_id
```

| Attribute     | Type           | Required | Description                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | integer or string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `freeze_period_id`    | string         | yes      | The database ID of the Freeze Period.                                     |

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

## Create a Freeze Period

Create a Freeze Period.

```plaintext
POST /projects/:id/freeze_periods
```

| Attribute          | Type            | Required                    | Description                                                                                                                      |
| -------------------| --------------- | --------                    | -------------------------------------------------------------------------------------------------------------------------------- |
| `id`               | integer or string  | yes                         | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding).                                              |
| `freeze_start`     | string          | yes                         | Start of the Freeze Period in [cron](https://crontab.guru/) format.                                                              |
| `freeze_end`       | string          | yes                         | End of the Freeze Period in [cron](https://crontab.guru/) format.                                                                |
| `cron_timezone`    | string          | no                          | The timezone for the cron fields, defaults to UTC if not provided.                                                               |

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

## Update a Freeze Period

Update a Freeze Period for the given `freeze_period_id`.

```plaintext
PUT /projects/:id/freeze_periods/:tag_name
```

| Attribute     | Type            | Required | Description                                                                                                 |
| ------------- | --------------- | -------- | ----------------------------------------------------------------------------------------------------------- |
| `id`          | integer or string  | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding).                         |
| `freeze_period_id`    | integer or string          | yes      | The database ID of the Freeze Period.                                                              |
| `freeze_start`     | string          | no                         | Start of the Freeze Period in [cron](https://crontab.guru/) format.                                                              |
| `freeze_end`       | string          | no                         | End of the Freeze Period in [cron](https://crontab.guru/) format.                                                                |
| `cron_timezone`    | string          | no                          | The timezone for the cron fields.                                                               |

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

## Delete a Freeze Period

Delete a Freeze Period for the given `freeze_period_id`.

```plaintext
DELETE /projects/:id/freeze_periods/:freeze_period_id
```

| Attribute     | Type           | Required | Description                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | integer or string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `freeze_period_id`    | string         | yes      | The database ID of the Freeze Period.                                     |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/19/freeze_periods/1"

```

---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Error Tracking API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to interact with the Error Tracking feature for projects. For more information, see [Error Tracking](../operations/error_tracking.md).

Prerequisites:

- You must have at least the Maintainer role.

## Get Error Tracking settings

Gets the Error Tracking settings for a specified project.

```plaintext
GET /projects/:id/error_tracking/settings
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id`      | integer | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/error_tracking/settings"
```

Example response:

```json
{
  "active": true,
  "project_name": "sample sentry project",
  "sentry_external_url": "https://sentry.io/myawesomeproject/project",
  "api_url": "https://sentry.io/api/0/projects/myawesomeproject/project",
  "integrated": false
}
```

## Create Error Tracking settings

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393035/) in GitLab 15.10.

{{< /history >}}

Creates Error Tracking settings for a specified project.

{{< alert type="note" >}}

This API is only available when used with [integrated error tracking](../operations/integrated_error_tracking.md).

{{< /alert >}}

```plaintext
PUT /projects/:id/error_tracking/settings
```

Supported attributes:

| Attribute    | Type    | Required | Description                                                                                                                                                     |
| ------------ | ------- |----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`         | integer | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).                                            |
| `active`     | boolean | yes      | Pass `true` to enable the error tracking setting configuration or `false` to disable it.                                                                        |
| `integrated` | boolean | yes      | Pass `true` to enable the integrated error tracking backend. |

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/error_tracking/settings?active=true&integrated=true"
```

Example response:

```json
{
  "active": true,
  "project_name": null,
  "sentry_external_url": null,
  "api_url": null,
  "integrated": true
}
```

## Activate the Error Tracking project settings

Activates or deactivates Error Tracking settings for a specified project.

```plaintext
PATCH /projects/:id/error_tracking/settings
```

| Attribute    | Type    | Required | Description           |
| ------------ | ------- | -------- | --------------------- |
| `id`         | integer | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `active`     | boolean | yes      | Pass `true` to enable the already configured error tracking settings or `false` to disable it. |
| `integrated` | boolean | no       | Pass `true` to enable the integrated error tracking backend. |

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/error_tracking/settings?active=true"
```

Example response:

```json
{
  "active": true,
  "project_name": "sample sentry project",
  "sentry_external_url": "https://sentry.io/myawesomeproject/project",
  "api_url": "https://sentry.io/api/0/projects/myawesomeproject/project",
  "integrated": false
}
```

## List all project client keys

Lists all [integrated error tracking](../operations/integrated_error_tracking.md) client keys for a specified project.

```plaintext
GET /projects/:id/error_tracking/client_keys
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/error_tracking/client_keys"
```

Example response:

```json
[
  {
    "id": 1,
    "active": true,
    "public_key": "glet_aa77551d849c083f76d0bc545ed053a3",
    "sentry_dsn": "https://glet_aa77551d849c083f76d0bc545ed053a3@example.com/errortracking/api/v1/projects/5"
  },
  {
    "id": 3,
    "active": true,
    "public_key": "glet_0ff98b1d849c083f76d0bc545ed053a3",
    "sentry_dsn": "https://glet_aa77551d849c083f76d0bc545ed053a3@example.com/errortracking/api/v1/projects/5"
  }
]
```

## Create a client key

Creates an [integrated error tracking](../operations/integrated_error_tracking.md) client key for a specified project. The public key attribute is generated automatically.

```plaintext
POST /projects/:id/error_tracking/client_keys
```

| Attribute  | Type | Required | Description |
| ---------  | ---- | -------- | ----------- |
| `id`       | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/5/error_tracking/client_keys"
```

Example response:

```json
{
  "id": 3,
  "active": true,
  "public_key": "glet_0ff98b1d849c083f76d0bc545ed053a3",
  "sentry_dsn": "https://glet_aa77551d849c083f76d0bc545ed053a3@example.com/errortracking/api/v1/projects/5"
}
```

## Delete a client key

Deletes an [integrated error tracking](../operations/integrated_error_tracking.md) client key from a specified project.

```plaintext
DELETE /projects/:id/error_tracking/client_keys/:key_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `key_id`  | integer | yes | The ID of the client key. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/error_tracking/client_keys/13"
```

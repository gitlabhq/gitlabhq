---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: System hooks API
description: "Set up and manage system hooks with the REST API."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Use this API to manage [system hooks](../administration/system_hooks.md). System hooks
are different from [group webhooks](group_webhooks.md) that impact all projects and subgroups
in a group, and [project webhooks](project_webhooks.md) that are limited to a single project.

Prerequisites:

- You must be an administrator.

## Configure a URL endpoint for system hooks

To configure a URL endpoint for system hooks:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **System hooks** (`/admin/hooks`).

## List system hooks

Get a list of all system hooks.

```plaintext
GET /hooks
```

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/hooks"
```

Example response:

```json
[
  {
    "id":1,
    "url":"https://gitlab.example.com/hook",
    "name": "Hook name",
    "description": "Hook description",
    "created_at":"2016-10-31T12:32:15.192Z",
    "push_events":true,
    "tag_push_events":false,
    "merge_requests_events": true,
    "repository_update_events": true,
    "enable_ssl_verification":true,
    "url_variables": []
  }
]
```

## Get system hook

Get a system hook by its ID.

```plaintext
GET /hooks/:id
```

| Attribute | Type    | Required | Description |
|-----------|---------|----------|-------------|
| `id`      | integer | Yes      | The ID of the hook. |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/hooks/1"
```

Example response:

```json
{
  "id": 1,
  "url": "https://gitlab.example.com/hook",
  "name": "Hook name",
  "description": "Hook description",
  "created_at": "2016-10-31T12:32:15.192Z",
  "push_events": true,
  "tag_push_events": false,
  "merge_requests_events": true,
  "repository_update_events": true,
  "enable_ssl_verification": true,
  "url_variables": []
}
```

## Add new system hook

Add a new system hook.

```plaintext
POST /hooks
```

| Attribute                   | Type    | Required | Description |
|-----------------------------|---------|----------|-------------|
| `url`                       | string  | Yes      | The hook URL. |
| `branch_filter_strategy`    | string  | No       | Filter push events by branch. Possible values are `wildcard` (default), `regex`, and `all_branches`. |
| `description`               | string  | No       | Description of the hook. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) in GitLab 17.1.) |
| `enable_ssl_verification`   | boolean | No       | Do SSL verification when triggering the hook. |
| `merge_requests_events`     | boolean | No       | Trigger hook on merge request events. |
| `name`                      | string  | No       | Name of the hook. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) in GitLab 17.1.) |
| `push_events`               | boolean | No       | When true, the hook fires on push events. |
| `push_events_branch_filter` | string  | No       | Trigger hook on push events for matching branches only. |
| `repository_update_events`  | boolean | No       | Trigger hook on repository update events. |
| `tag_push_events`           | boolean | No       | When true, the hook fires on new tags being pushed. |
| `token`                     | string  | No       | Secret token to validate received payloads. Not returned in the response. |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/hooks?url=https://gitlab.example.com/hook"
```

Example response:

```json
[
  {
    "id":1,
    "url":"https://gitlab.example.com/hook",
    "name": "Hook name",
    "description": "Hook description",
    "created_at":"2016-10-31T12:32:15.192Z",
    "push_events":true,
    "tag_push_events":false,
    "merge_requests_events": true,
    "repository_update_events": true,
    "enable_ssl_verification":true,
    "url_variables": []
  }
]
```

## Update system hook

Update an existing system hook.

```plaintext
PUT /hooks/:hook_id
```

| Attribute                   | Type    | Required | Description |
|-----------------------------|---------|----------|-------------|
| `hook_id`                   | integer | Yes      | The ID of the system hook. |
| `branch_filter_strategy`    | string  | No       | Filter push events by branch. Possible values are `wildcard` (default), `regex`, and `all_branches`. |
| `enable_ssl_verification`   | boolean | No       | Do SSL verification when triggering the hook. |
| `merge_requests_events`     | boolean | No       | Trigger hook on merge request events. |
| `push_events`               | boolean | No       | When true, the hook fires on push events. |
| `push_events_branch_filter` | string  | No       | Trigger hook on push events for matching branches only. |
| `repository_update_events`  | boolean | No       | Trigger hook on repository update events. |
| `tag_push_events`           | boolean | No       | When true, the hook fires on new tags being pushed. |
| `token`                     | string  | No       | Secret token to validate received payloads; this isn't returned in the response. |
| `url`                       | string  | No       | The hook URL. |

## Test system hook

Executes the system hook with mock data.

```plaintext
POST /hooks/:id
```

| Attribute | Type    | Required | Description |
|-----------|---------|----------|-------------|
| `id`      | integer | Yes      | The ID of the hook. |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/hooks/1"
```

The response is always the mock data:

```json
{
   "project_id" : 1,
   "owner_email" : "example@gitlabhq.com",
   "owner_name" : "Someone",
   "name" : "Ruby",
   "path" : "ruby",
   "event_name" : "project_create"
}
```

## Delete system hook

Deletes a system hook.

```plaintext
DELETE /hooks/:id
```

| Attribute | Type    | Required | Description |
|-----------|---------|----------|-------------|
| `id`      | integer | Yes      | The ID of the hook. |

Example request:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/hooks/2"
```

## Set a URL variable

```plaintext
PUT /hooks/:hook_id/url_variables/:key
```

Supported attributes:

| Attribute | Type    | Required | Description |
|-----------|---------|----------|-------------|
| `hook_id` | integer | Yes      | ID of the system hook. |
| `key`     | string  | Yes      | Key of the URL variable. |
| `value`   | string  | Yes      | Value of the URL variable. |

On success, this endpoint returns the response code `204 No Content`.

## Delete a URL variable

```plaintext
DELETE /hooks/:hook_id/url_variables/:key
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `hook_id` | integer           | Yes      | ID of the system hook. |
| `key`     | string            | Yes      | Key of the URL variable. |

On success, this endpoint returns the response code `204 No Content`.

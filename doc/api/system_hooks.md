---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
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

## List all system hooks

Lists all system hooks.

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
    "url_variables": [],
    "token_present": false,
    "signing_token_present": false
  }
]
```

## Retrieve system hook

{{< history >}}

- `name` and `description` attributes [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) in GitLab 17.1.
- `token_present` and `signing_token_present` attributes [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325) in GitLab 19.0.

{{< /history >}}

Retrieves a system hook by its ID.

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
  "url_variables": [],
  "token_present": false,
  "signing_token_present": false
}
```

## Add new system hook

{{< history >}}

- `name` and `description` attributes [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) in GitLab 17.1.
- `signing_token` attribute [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325) in GitLab 19.0 [with a flag](../administration/feature_flags/_index.md) named `webhook_signing_token`. Enabled by default.

{{< /history >}}

> [!flag]
> The availability of the `signing_token` attribute is controlled by a feature flag.
> For more information, see the history.

Adds a new system hook.

```plaintext
POST /hooks
```

| Attribute                   | Type    | Required | Description |
|-----------------------------|---------|----------|-------------|
| `url`                       | string  | Yes      | The hook URL. |
| `branch_filter_strategy`    | string  | No       | Filter push events by branch. Possible values are `wildcard` (default), `regex`, and `all_branches`. |
| `description`               | string  | No       | Description of the hook. |
| `enable_ssl_verification`   | boolean | No       | Do SSL verification when triggering the hook. |
| `merge_requests_events`     | boolean | No       | Trigger hook on merge request events. |
| `name`                      | string  | No       | Name of the hook. |
| `push_events`               | boolean | No       | When true, the hook fires on push events. |
| `push_events_branch_filter` | string  | No       | Trigger hook on push events for matching branches only. |
| `repository_update_events`  | boolean | No       | Trigger hook on repository update events. |
| `signing_token`             | string  | No       | HMAC signing token used to compute the `webhook-signature` header. Must be in `whsec_<base64>` format encoding a 32-byte key. Not returned in the response. |
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
    "url_variables": [],
    "token_present": false,
    "signing_token_present": false
  }
]
```

## Update system hook

{{< history >}}

- `name` and `description` attributes [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) in GitLab 17.1.
- `signing_token` attribute [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325) in GitLab 19.0 [with a flag](../administration/feature_flags/_index.md) named `webhook_signing_token`. Enabled by default.

{{< /history >}}

> [!flag]
> The availability of the `signing_token` attribute is controlled by a feature flag.
> For more information, see the history.

Updates an existing system hook.

```plaintext
PUT /hooks/:hook_id
```

| Attribute                   | Type    | Required | Description |
|-----------------------------|---------|----------|-------------|
| `hook_id`                   | integer | Yes      | The ID of the system hook. |
| `branch_filter_strategy`    | string  | No       | Filter push events by branch. Possible values are `wildcard` (default), `regex`, and `all_branches`. |
| `description`               | string  | No       | Description of the hook. |
| `enable_ssl_verification`   | boolean | No       | Do SSL verification when triggering the hook. |
| `merge_requests_events`     | boolean | No       | Trigger hook on merge request events. |
| `name`                      | string  | No       | Name of the hook. |
| `push_events`               | boolean | No       | When true, the hook fires on push events. |
| `push_events_branch_filter` | string  | No       | Trigger hook on push events for matching branches only. |
| `repository_update_events`  | boolean | No       | Trigger hook on repository update events. |
| `signing_token`             | string  | No       | HMAC signing token used to compute the `webhook-signature` header. Must be in `whsec_<base64>` format encoding a 32-byte key. Not returned in the response. |
| `tag_push_events`           | boolean | No       | When true, the hook fires on new tags being pushed. |
| `token`                     | string  | No       | Secret token to validate received payloads. Not returned in the response. |
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

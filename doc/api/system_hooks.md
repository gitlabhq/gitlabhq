---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# System hooks API

All methods require administrator authorization.

You can configure the URL endpoint of the system hooks from the GitLab user interface:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. Select **System Hooks** (`/admin/hooks`).

Read more about [system hooks](../system_hooks/system_hooks.md).

## List system hooks

Get a list of all system hooks.

```plaintext
GET /hooks
```

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/hooks"
```

Example response:

```json
[
  {
    "id":1,
    "url":"https://gitlab.example.com/hook",
    "created_at":"2016-10-31T12:32:15.192Z",
    "push_events":true,
    "tag_push_events":false,
    "merge_requests_events": true,
    "repository_update_events": true,
    "enable_ssl_verification":true
  }
]
```

## Add new system hook

Add a new system hook.

```plaintext
POST /hooks
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `url` | string | yes | The hook URL |
| `token` | string | no | Secret token to validate received payloads; this isn't returned in the response |
| `push_events` | boolean |  no | When true, the hook fires on push events |
| `tag_push_events` | boolean | no | When true, the hook fires on new tags being pushed |
| `merge_requests_events` | boolean | no | Trigger hook on merge requests events |
| `repository_update_events` | boolean | no | Trigger hook on repository update events |
| `enable_ssl_verification` | boolean | no | Do SSL verification when triggering the hook |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/hooks?url=https://gitlab.example.com/hook"
```

Example response:

```json
[
  {
    "id":1,
    "url":"https://gitlab.example.com/hook",
    "created_at":"2016-10-31T12:32:15.192Z",
    "push_events":true,
    "tag_push_events":false,
    "merge_requests_events": true,
    "repository_update_events": true,
    "enable_ssl_verification":true
  }
]
```

## Test system hook

```plaintext
POST /hooks/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the hook |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/hooks/1"
```

Example response:

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

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the hook |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/hooks/2"
```

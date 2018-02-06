# System hooks API

All methods require administrator authorization.

The URL endpoint of the system hooks can also be configured using the UI in
the admin area under **Hooks** (`/admin/hooks`).

Read more about [system hooks](../system_hooks/system_hooks.md).

## List system hooks

Get a list of all system hooks.

---

```
GET /hooks
```

Example request:

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/hooks
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
    "enable_ssl_verification":true
  }
]
```

## Add new system hook

Add a new system hook.

---

```
POST /hooks
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `url` | string | yes | The hook URL |
| `token` | string | no | Secret token to validate received payloads; this will not be returned in the response |
| `push_events` | boolean |  no | When true, the hook will fire on push events |
| `tag_push_events` | boolean | no | When true, the hook will fire on new tags being pushed |
| `merge_requests_events` | boolean | no | Trigger hook on merge requests events |
| `enable_ssl_verification` | boolean | no | Do SSL verification when triggering the hook |

Example request:

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/hooks?url=https://gitlab.example.com/hook"
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
    "enable_ssl_verification":true
  }
]
```

## Test system hook

```
GET /hooks/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the hook |

Example request:

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/hooks/2
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

---

```
DELETE /hooks/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the hook |

Example request:

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/hooks/2
```

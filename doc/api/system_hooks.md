# System hooks

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
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/hooks
```

Example response:

```json
[
   {
      "id" : 1,
      "url" : "https://gitlab.example.com/hook",
      "created_at" : "2015-11-04T20:07:35.874Z"
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

Example request:

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/hooks?url=https://gitlab.example.com/hook"
```

Example response:

```json
[
   {
      "id" : 2,
      "url" : "https://gitlab.example.com/hook",
      "created_at" : "2015-11-04T20:07:35.874Z"
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
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/hooks/2
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

Deletes a system hook. This is an idempotent API function and returns `200 OK`
even if the hook is not available.

If the hook is deleted, a JSON object is returned. An error is raised if the
hook is not found.

---

```
DELETE /hooks/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the hook |

Example request:

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/hooks/2
```

Example response:

```json
{
   "note_events" : false,
   "project_id" : null,
   "enable_ssl_verification" : true,
   "url" : "https://gitlab.example.com/hook",
   "updated_at" : "2015-11-04T20:12:15.931Z",
   "issues_events" : false,
   "merge_requests_events" : false,
   "created_at" : "2015-11-04T20:12:15.931Z",
   "service_id" : null,
   "id" : 2,
   "push_events" : true,
   "tag_push_events" : false
}
```

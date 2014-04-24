# System hooks

All methods require admin authorization.

The URL endpoint of the system hooks can be configured in [the admin area under hooks](/admin/hooks).

## List system hooks

Get list of system hooks

```
GET /hooks
```

Parameters:

- **none**

```json
[
  {
    "id": 3,
    "url": "http://example.com/hook",
    "created_at": "2013-10-02T10:15:31Z"
  }
]
```

## Add new system hook hook

```
POST /hooks
```

Parameters:

- `url` (required) - The hook URL

## Test system hook

```
GET /hooks/:id
```

Parameters:

- `id` (required) - The ID of hook

```json
{
  "event_name": "project_create",
  "name": "Ruby",
  "path": "ruby",
  "project_id": 1,
  "owner_name": "Someone",
  "owner_email": "example@gitlabhq.com"
}
```

## Delete system hook

Deletes a system hook. This is an idempotent API function and returns `200 Ok` even if the hook is not available. If the hook is deleted it is also returned as JSON.

```
DELETE /hooks/:id
```

Parameters:

- `id` (required) - The ID of hook

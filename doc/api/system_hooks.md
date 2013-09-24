All methods require admin authorization.

## List system hooks

Get list of system hooks

```
GET /hooks
```

Parameters:

+ **none**


## Add new system hook hook

```
POST /hooks
```

Parameters:

+ `url` (required) - The hook URL


## Test system hook

```
GET /hooks/:id
```

Parameters:

+ `id` (required) - The ID of hook


## Delete system hook

Deletes a system hook. This is an idempotent API function and returns `200 Ok` even if the hook
is not available. If the hook is deleted it is also returned as JSON.

```
DELETE /hooks/:id
```

Parameters:

+ `id` (required) - The ID of hook

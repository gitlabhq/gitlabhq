All methods require admin authorization.

## List system hooks

Get list of system hooks

```
GET /hooks
```

Will return hooks with status `200 OK` on success, or `404 Not found` on fail.

## Add new system hook hook

```
POST /hooks
```

Parameters:

+ `url` (required) - The hook URL

Will return status `201 Created` on success, or `404 Not found` on fail.

## Test system hook

```
GET /hooks/:id
```

Parameters:

+ `id` (required) - The ID of hook

Will return hook with status `200 OK` on success, or `404 Not found` on fail.

## Delete system hook

```
DELETE /hooks/:id
```

Parameters:

+ `id` (required) - The ID of hook

Will return status `200 OK` on success, or `404 Not found` on fail.
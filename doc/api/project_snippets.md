# Project snippets

### Snippet visibility level

Snippets in GitLab can be either private, internal or public.
You can set it with the `visibility_level` field in the snippet.

Constants for snippet visibility levels are:

| Visibility | visibility_level | Description |
| ---------- | ---------------- | ----------- |
| Private    | `0`  | The snippet is visible only the snippet creator |
| Internal   | `10` | The snippet is visible for any logged in user |
| Public     | `20` | The snippet can be accessed without any authentication |

## List snippets

Get a list of project snippets.

```
GET /projects/:id/snippets
```

Parameters:

- `id` (required) - The ID of a project

## Single snippet

Get a single project snippet.

```
GET /projects/:id/snippets/:snippet_id
```

Parameters:

- `id` (required) - The ID of a project
- `snippet_id` (required) - The ID of a project's snippet

```json
{
  "id": 1,
  "title": "test",
  "file_name": "add.rb",
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "created_at": "2012-05-23T08:00:58Z"
  },
  "expires_at": null,
  "updated_at": "2012-06-28T10:52:04Z",
  "created_at": "2012-06-28T10:52:04Z",
  "web_url": "http://example.com/example/example/snippets/1"
}
```

## Create new snippet

Creates a new project snippet. The user must have permission to create new snippets.

```
POST /projects/:id/snippets
```

Parameters:

- `id` (required) - The ID of a project
- `title` (required) - The title of a snippet
- `file_name` (required) - The name of a snippet file
- `code` (required) - The content of a snippet
- `visibility_level` (required) - The snippet's visibility

## Update snippet

Updates an existing project snippet. The user must have permission to change an existing snippet.

```
PUT /projects/:id/snippets/:snippet_id
```

Parameters:

- `id` (required) - The ID of a project
- `snippet_id` (required) - The ID of a project's snippet
- `title` (optional) - The title of a snippet
- `file_name` (optional) - The name of a snippet file
- `code` (optional) - The content of a snippet
- `visibility_level` (optional) - The snippet's visibility

## Delete snippet

Deletes an existing project snippet. This is an idempotent function and deleting a non-existent
snippet still returns a `200 OK` status code.

```
DELETE /projects/:id/snippets/:snippet_id
```

Parameters:

- `id` (required) - The ID of a project
- `snippet_id` (required) - The ID of a project's snippet

## Snippet content

Returns the raw project snippet as plain text.

```
GET /projects/:id/snippets/:snippet_id/raw
```

Parameters:

- `id` (required) - The ID of a project
- `snippet_id` (required) - The ID of a project's snippet

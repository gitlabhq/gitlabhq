# Project snippets

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
  "created_at": "2012-06-28T10:52:04Z"
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

## Delete snippet

Deletes an existing project snippet. This is an idempotent function and deleting a non-existent
snippet still returns a `200 Ok` status code.

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

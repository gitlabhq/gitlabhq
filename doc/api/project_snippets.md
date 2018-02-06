# Project snippets

### Snippet visibility level

Snippets in GitLab can be either private, internal or public.
You can set it with the `visibility` field in the snippet.

Constants for snippet visibility levels are:

| visibility | Description |
| ---------- | ----------- |
| `private`  | The snippet is visible only the snippet creator |
| `internal` | The snippet is visible for any logged in user |
| `public`   | The snippet can be accessed without any authentication |

## List snippets

Get a list of project snippets.

```
GET /projects/:id/snippets
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user

## Single snippet

Get a single project snippet.

```
GET /projects/:id/snippets/:snippet_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `snippet_id` (required) - The ID of a project's snippet

```json
{
  "id": 1,
  "title": "test",
  "file_name": "add.rb",
  "description": "Ruby test snippet",
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "created_at": "2012-05-23T08:00:58Z"
  },
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

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `title` (required) - The title of a snippet
- `file_name` (required) - The name of a snippet file
- `description` (optional) - The description of a snippet
- `code` (required) - The content of a snippet
- `visibility` (required) - The snippet's visibility

## Update snippet

Updates an existing project snippet. The user must have permission to change an existing snippet.

```
PUT /projects/:id/snippets/:snippet_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `snippet_id` (required) - The ID of a project's snippet
- `title` (optional) - The title of a snippet
- `file_name` (optional) - The name of a snippet file
- `description` (optional) - The description of a snippet
- `code` (optional) - The content of a snippet
- `visibility` (optional) - The snippet's visibility

## Delete snippet

Deletes an existing project snippet. This returns a `204 No Content` status code if the operation was successfully or `404` if the resource was not found.

```
DELETE /projects/:id/snippets/:snippet_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `snippet_id` (required) - The ID of a project's snippet

## Snippet content

Returns the raw project snippet as plain text.

```
GET /projects/:id/snippets/:snippet_id/raw
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `snippet_id` (required) - The ID of a project's snippet

## Get user agent details

> **Notes:**
> [Introduced][ce-29508] in GitLab 9.4.


Available only for admins.

```
GET /projects/:id/snippets/:snippet_id/user_agent_detail
```

| Attribute     | Type    | Required | Description                          |
|---------------|---------|----------|--------------------------------------|
| `id`          | Integer | yes      | The ID of a project                  |
| `snippet_id`  | Integer | yes      | The ID of a snippet                  |

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/1/snippets/2/user_agent_detail
```

Example response:

```json
{
  "user_agent": "AppleWebKit/537.36",
  "ip_address": "127.0.0.1",
  "akismet_submitted": false
}
```

[ce-29508]: https://gitlab.com/gitlab-org/gitlab-ce/issues/29508

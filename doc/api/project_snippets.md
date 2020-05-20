# Project snippets

## Snippet visibility level

Snippets in GitLab can be either private, internal or public.
You can set it with the `visibility` field in the snippet.

Constants for snippet visibility levels are:

| visibility | Description |
| ---------- | ----------- |
| `private`  | The snippet is visible only the snippet creator |
| `internal` | The snippet is visible for any logged in user |
| `public`   | The snippet can be accessed without any authentication |

NOTE: **Note:**
From July 2019, the `Internal` visibility setting is disabled for new projects, groups,
and snippets on GitLab.com. Existing projects, groups, and snippets using the `Internal`
visibility setting keep this setting. You can read more about the change in the
[relevant issue](https://gitlab.com/gitlab-org/gitlab/issues/12388).

## List snippets

Get a list of project snippets.

```plaintext
GET /projects/:id/snippets
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user

## Single snippet

Get a single project snippet.

```plaintext
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
  "project_id": 1,
  "web_url": "http://example.com/example/example/snippets/1",
  "raw_url": "http://example.com/example/example/snippets/1/raw"
}
```

## Create new snippet

Creates a new project snippet. The user must have permission to create new snippets.

```plaintext
POST /projects/:id/snippets
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `title` (required) - The title of a snippet
- `file_name` (required) - The name of a snippet file
- `description` (optional) - The description of a snippet
- `content` (required) - The content of a snippet
- `visibility` (required) - The snippet's visibility

Example request:

```shell
curl --request POST https://gitlab.com/api/v4/projects/:id/snippets \
     --header "PRIVATE-TOKEN: <your access token>" \
     --header "Content-Type: application/json" \
     -d @snippet.json
```

`snippet.json` used in the above example request:

```json
{
  "title" : "Example Snippet Title",
  "description" : "More verbose snippet description",
  "file_name" : "example.txt",
  "content" : "source code \n with multiple lines\n",
  "visibility" : "private"
}
```

## Update snippet

Updates an existing project snippet. The user must have permission to change an existing snippet.

```plaintext
PUT /projects/:id/snippets/:snippet_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `snippet_id` (required) - The ID of a project's snippet
- `title` (optional) - The title of a snippet
- `file_name` (optional) - The name of a snippet file
- `description` (optional) - The description of a snippet
- `content` (optional) - The content of a snippet
- `visibility` (optional) - The snippet's visibility

Example request:

```shell
curl --request PUT https://gitlab.com/api/v4/projects/:id/snippets/:snippet_id \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     -d @snippet.json
```

`snippet.json` used in the above example request:

```json
{
  "title" : "Updated Snippet Title",
  "description" : "More verbose snippet description",
  "file_name" : "new_filename.txt",
  "content" : "updated source code \n with multiple lines\n",
  "visibility" : "private"
}
```

## Delete snippet

Deletes an existing project snippet. This returns a `204 No Content` status code if the operation was successfully or `404` if the resource was not found.

```plaintext
DELETE /projects/:id/snippets/:snippet_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `snippet_id` (required) - The ID of a project's snippet

Example request:

```shell
curl --request DELETE https://gitlab.com/api/v4/projects/:id/snippets/:snippet_id \
     --header "PRIVATE-TOKEN: <your_access_token>"
```

## Snippet content

Returns the raw project snippet as plain text.

```plaintext
GET /projects/:id/snippets/:snippet_id/raw
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `snippet_id` (required) - The ID of a project's snippet

Example request:

```shell
curl https://gitlab.com/api/v4/projects/:id/snippets/:snippet_id/raw \
     --header "PRIVATE-TOKEN: <your_access_token>"
```

## Get user agent details

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/29508) in GitLab 9.4.

Available only for admins.

```plaintext
GET /projects/:id/snippets/:snippet_id/user_agent_detail
```

| Attribute     | Type    | Required | Description                          |
|---------------|---------|----------|--------------------------------------|
| `id`          | Integer | yes      | The ID of a project                  |
| `snippet_id`  | Integer | yes      | The ID of a snippet                  |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/1/snippets/2/user_agent_detail
```

Example response:

```json
{
  "user_agent": "AppleWebKit/537.36",
  "ip_address": "127.0.0.1",
  "akismet_submitted": false
}
```

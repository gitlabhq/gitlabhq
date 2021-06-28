---
stage: Create
group: Editor
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, api
---

# Project snippets **(FREE)**

## Snippet visibility level

Snippets in GitLab can be either private, internal or public.
You can set it with the `visibility` field in the snippet.

Constants for snippet visibility levels are:

| visibility | Description |
| ---------- | ----------- |
| `private`  | The snippet is visible only to the snippet creator |
| `internal` | The snippet is visible for any logged in user except [external users](../user/permissions.md#external-users) |
| `public`   | The snippet can be accessed without any authentication |

NOTE:
From July 2019, the `Internal` visibility setting is disabled for new projects, groups,
and snippets on GitLab.com. Existing projects, groups, and snippets using the `Internal`
visibility setting keep this setting. You can read more about the change in the
[relevant issue](https://gitlab.com/gitlab-org/gitlab/-/issues/12388).

## List snippets

Get a list of project snippets.

```plaintext
GET /projects/:id/snippets
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user

## Single snippet

Get a single project snippet.

```plaintext
GET /projects/:id/snippets/:snippet_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user
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

| Attribute         | Type            | Required | Description                                                                                                     |
|:------------------|:----------------|:---------|:----------------------------------------------------------------------------------------------------------------|
| `id`              | integer         | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `title`           | string          | yes      | Title of a snippet                                                                                              |
| `file_name`       | string          | no       | Deprecated: Use `files` instead. Name of a snippet file                                                         |
| `content`         | string          | no       | Deprecated: Use `files` instead. Content of a snippet                                                           |
| `description`     | string          | no       | Description of a snippet                                                                                        |
| `visibility`      | string          | no       | Snippet's [visibility](#snippet-visibility-level)                                                               |
| `files`           | array of hashes | no       | An array of snippet files                                                                                       |
| `files:file_path` | string          | yes      | File path of the snippet file                                                                                   |
| `files:content`   | string          | yes      | Content of the snippet file                                                                                     |

Example request:

```shell
curl --request POST "https://gitlab.com/api/v4/projects/:id/snippets" \
     --header "PRIVATE-TOKEN: <your access token>" \
     --header "Content-Type: application/json" \
     -d @snippet.json
```

`snippet.json` used in the above example request:

```json
{
  "title" : "Example Snippet Title",
  "description" : "More verbose snippet description",
  "visibility" : "private",
  "files": [
    {
      "file_path": "example.txt",
      "content" : "source code \n with multiple lines\n"
    }
  ]
}
```

## Update snippet

Updates an existing project snippet. The user must have permission to change an existing snippet.

```plaintext
PUT /projects/:id/snippets/:snippet_id
```

Parameters:

| Attribute             | Type            | Required | Description                                                                                                     |
|:----------------------|:----------------|:---------|:----------------------------------------------------------------------------------------------------------------|
| `id`                  | integer         | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `snippet_id`          | integer         | yes      | The ID of a project's snippet                                                                                   |
| `title`               | string          | no       | Title of a snippet                                                                                              |
| `file_name`           | string          | no       | Deprecated: Use `files` instead. Name of a snippet file                                                         |
| `content`             | string          | no       | Deprecated: Use `files` instead. Content of a snippet                                                           |
| `description`         | string          | no       | Description of a snippet                                                                                        |
| `visibility`          | string          | no       | Snippet's [visibility](#snippet-visibility-level)                                                               |
| `files`               | array of hashes | no       | An array of snippet files                                                                                       |
| `files:action`        | string          | yes      | Type of action to perform on the file, one of: `create`, `update`, `delete`, `move`                             |
| `files:file_path`     | string          | no       | File path of the snippet file                                                                                   |
| `files:previous_path` | string          | no       | Previous path of the snippet file                                                                               |
| `files:content`       | string          | no       | Content of the snippet file                                                                                     |

Updates to snippets with multiple files *must* use the `files` attribute.

Example request:

```shell
curl --request PUT "https://gitlab.com/api/v4/projects/:id/snippets/:snippet_id" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     -d @snippet.json
```

`snippet.json` used in the above example request:

```json
{
  "title" : "Updated Snippet Title",
  "description" : "More verbose snippet description",
  "visibility" : "private",
  "files": [
    {
      "action": "update",
      "file_path": "example.txt",
      "content" : "updated source code \n with multiple lines\n"
    }
  ]
}
```

## Delete snippet

Deletes an existing project snippet. This returns a `204 No Content` status code if the operation was successfully or `404` if the resource was not found.

```plaintext
DELETE /projects/:id/snippets/:snippet_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user
- `snippet_id` (required) - The ID of a project's snippet

Example request:

```shell
curl --request DELETE "https://gitlab.com/api/v4/projects/:id/snippets/:snippet_id" \
     --header "PRIVATE-TOKEN: <your_access_token>"
```

## Snippet content

Returns the raw project snippet as plain text.

```plaintext
GET /projects/:id/snippets/:snippet_id/raw
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user
- `snippet_id` (required) - The ID of a project's snippet

Example request:

```shell
curl "https://gitlab.com/api/v4/projects/:id/snippets/:snippet_id/raw" \
     --header "PRIVATE-TOKEN: <your_access_token>"
```

## Snippet repository file content

Returns the raw file content as plain text.

```plaintext
GET /projects/:id/snippets/:snippet_id/files/:ref/:file_path/raw
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user
- `snippet_id` (required) - The ID of a project's snippet
- `ref` (required) - The name of a branch, tag or commit, such as `main`
- `file_path` (required) - The URL-encoded path to the file, such as `snippet%2Erb`

Example request:

```shell
curl "https://gitlab.com/api/v4/projects/1/snippets/2/files/master/snippet%2Erb/raw" \
     --header "PRIVATE-TOKEN: <your_access_token>"
```

## Get user agent details

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/29508) in GitLab 9.4.

Available only for users with the Administrator [role](../user/permissions.md).

```plaintext
GET /projects/:id/snippets/:snippet_id/user_agent_detail
```

| Attribute     | Type    | Required | Description                          |
|---------------|---------|----------|--------------------------------------|
| `id`          | integer or string | yes      | The ID or [URL-encoded path of a project](index.md#namespaced-path-encoding). |
| `snippet_id`  | Integer | yes      | The ID of a snippet                  |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/snippets/2/user_agent_detail"
```

Example response:

```json
{
  "user_agent": "AppleWebKit/537.36",
  "ip_address": "127.0.0.1",
  "akismet_submitted": false
}
```

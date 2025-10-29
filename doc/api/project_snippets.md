---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Project snippets
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to manage [project snippets](../user/snippets.md).

## Snippet visibility level

[Snippets](project_snippets.md) in GitLab can be either private, internal or public.
You can set it with the `visibility` field in the snippet.

Constants for snippet visibility levels are:

- **Private**: The snippet is visible only to project members.
- **Internal**: The snippet is visible for any authenticated user except [external users](../administration/external_users.md).
- **Public**: The snippet can be accessed without any authentication.

{{< alert type="note" >}}

From July 2019, the `Internal` visibility setting is disabled for new projects, groups,
and snippets on GitLab.com. Existing projects, groups, and snippets using the `Internal`
visibility setting keep this setting. You can read more about the change in the
[relevant issue](https://gitlab.com/gitlab-org/gitlab/-/issues/12388).

{{< /alert >}}

## List snippets

Get a list of project snippets.

```plaintext
GET /projects/:id/snippets
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute           | Type    | Description |
|---------------------|---------|-------------|
| `author.created_at` | string  | Date and time when the author account was created. |
| `author.email`      | string  | Email address of the snippet author. |
| `author.id`         | integer | ID of the snippet author. |
| `author.name`       | string  | Display name of the snippet author. |
| `author.state`      | string  | State of the author account. |
| `author.username`   | string  | Username of the snippet author. |
| `created_at`        | string  | Date and time when the snippet was created in ISO 8601 format. |
| `description`       | string  | Description of the snippet. |
| `file_name`         | string  | Name of the snippet file. |
| `id`                | integer | ID of the snippet. |
| `imported`          | boolean | If `true`, the snippet was imported. |
| `imported_from`     | string  | Source of the import if the snippet was imported. |
| `project_id`        | integer | ID of the project containing the snippet. |
| `raw_url`           | string  | Direct URL to the raw snippet content. |
| `title`             | string  | Title of the snippet. |
| `updated_at`        | string  | Date and time when the snippet was last updated in ISO 8601 format. |
| `web_url`           | string  | URL to view the snippet in the GitLab web interface. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets"
```

Example response:

```json
[
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
    "imported": false,
    "imported_from": "none",
    "project_id": 1,
    "web_url": "http://example.com/example/example/snippets/1",
    "raw_url": "http://example.com/example/example/snippets/1/raw"
  },
  {
    "id": 3,
    "title": "Configuration helper",
    "file_name": "config.yml",
    "description": "YAML configuration snippet",
    "author": {
      "id": 2,
      "username": "jane_doe",
      "email": "jane@example.com",
      "name": "Jane Doe",
      "state": "active",
      "created_at": "2013-02-15T10:30:20Z"
    },
    "updated_at": "2013-03-10T14:15:30Z",
    "created_at": "2013-03-01T09:45:12Z",
    "imported": false,
    "imported_from": "none",
    "project_id": 1,
    "web_url": "http://example.com/example/example/snippets/3",
    "raw_url": "http://example.com/example/example/snippets/3/raw"
  }
]
```

## Get single snippet

Get a single project snippet.

```plaintext
GET /projects/:id/snippets/:snippet_id
```

Supported attributes:

| Attribute    | Type              | Required | Description |
|--------------|-------------------|----------|-------------|
| `id`         | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `snippet_id` | integer           | Yes      | ID of a project's snippet. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute           | Type    | Description |
|---------------------|---------|-------------|
| `author.created_at` | string  | Date and time when the author account was created. |
| `author.email`      | string  | Email address of the snippet author. |
| `author.id`         | integer | ID of the snippet author. |
| `author.name`       | string  | Display name of the snippet author. |
| `author.state`      | string  | State of the author account. |
| `author.username`   | string  | Username of the snippet author. |
| `created_at`        | string  | Date and time when the snippet was created in ISO 8601 format. |
| `description`       | string  | Description of the snippet. |
| `file_name`         | string  | Name of the snippet file. |
| `id`                | integer | ID of the snippet. |
| `imported`          | boolean | If `true`, the snippet was imported. |
| `imported_from`     | string  | Source of the import if the snippet was imported. |
| `project_id`        | integer | ID of the project containing the snippet. |
| `raw_url`           | string  | Direct URL to the raw snippet content. |
| `title`             | string  | Title of the snippet. |
| `updated_at`        | string  | Date and time when the snippet was last updated in ISO 8601 format. |
| `web_url`           | string  | URL to view the snippet in the GitLab web interface. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2"
```

Example response:

```json
{
  "id": 2,
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
  "imported": false,
  "imported_from": "none",
  "project_id": 1,
  "web_url": "http://example.com/example/example/snippets/2",
  "raw_url": "http://example.com/example/example/snippets/2/raw"
}
```

## Create new snippet

Creates a new project snippet. The user must have permission to create new snippets.

```plaintext
POST /projects/:id/snippets
```

Supported attributes:

| Attribute         | Type              | Required | Description |
|-------------------|-------------------|----------|-------------|
| `files`           | array of hashes   | Yes      | An array of snippet files. |
| `files:content`   | string            | Yes      | Content of the snippet file. |
| `files:file_path` | string            | Yes      | File path of the snippet file. |
| `id`              | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `title`           | string            | Yes      | Title of a snippet. |
| `content`         | string            | No       | Deprecated: Use `files` instead. Content of a snippet. |
| `description`     | string            | No       | Description of a snippet. |
| `file_name`       | string            | No       | Deprecated: Use `files` instead. Name of a snippet file. |
| `visibility`      | string            | No       | Snippet's [visibility](#snippet-visibility-level). |

If successful, returns [`201 Created`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute           | Type    | Description |
|---------------------|---------|-------------|
| `author.created_at` | string  | Date and time when the author account was created. |
| `author.email`      | string  | Email address of the snippet author. |
| `author.id`         | integer | ID of the snippet author. |
| `author.name`       | string  | Display name of the snippet author. |
| `author.state`      | string  | State of the author account. |
| `author.username`   | string  | Username of the snippet author. |
| `created_at`        | string  | Date and time when the snippet was created in ISO 8601 format. |
| `description`       | string  | Description of the snippet. |
| `file_name`         | string  | Name of the snippet file. |
| `id`                | integer | ID of the snippet. |
| `imported`          | boolean | If `true`, the snippet was imported. |
| `imported_from`     | string  | Source of the import if the snippet was imported. |
| `project_id`        | integer | ID of the project containing the snippet. |
| `raw_url`           | string  | Direct URL to the raw snippet content. |
| `title`             | string  | Title of the snippet. |
| `updated_at`        | string  | Date and time when the snippet was last updated in ISO 8601 format. |
| `web_url`           | string  | URL to view the snippet in the GitLab web interface. |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"title": "Example Snippet Title", "description": "More verbose snippet description", "visibility": "private", "files": [{"file_path": "example.txt", "content": "source code \n with multiple lines\n"}]}' \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets"
```

Example response:

```json
{
  "id": 1,
  "title": "Example Snippet Title",
  "file_name": "example.txt",
  "description": "More verbose snippet description",
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
  "imported": false,
  "imported_from": "none",
  "project_id": 1,
  "web_url": "http://example.com/example/example/snippets/1",
  "raw_url": "http://example.com/example/example/snippets/1/raw"
}
```

## Update snippet

Updates an existing project snippet. The user must have permission to change an existing snippet.

Updates to snippets with multiple files must use the `files` attribute.

```plaintext
PUT /projects/:id/snippets/:snippet_id
```

Supported attributes:

| Attribute             | Type              | Required      | Description |
|-----------------------|-------------------|---------------|-------------|
| `id`                  | integer or string | Yes           | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `snippet_id`          | integer           | Yes           | ID of a project's snippet. |
| `files:action`        | string            | Conditionally | Type of action to perform on the file. One of: `create`, `update`, `delete`, `move`. Required when using the `files` attribute. |
| `content`             | string            | No            | Deprecated: Use `files` instead. Content of a snippet. |
| `description`         | string            | No            | Description of a snippet. |
| `file_name`           | string            | No            | Deprecated: Use `files` instead. Name of a snippet file. |
| `files`               | array of hashes   | No            | An array of snippet files. |
| `files:content`       | string            | No            | Content of the snippet file. |
| `files:file_path`     | string            | No            | File path of the snippet file. |
| `files:previous_path` | string            | No            | Previous path of the snippet file. |
| `title`               | string            | No            | Title of a snippet. |
| `visibility`          | string            | No            | Snippet's [visibility](#snippet-visibility-level). |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute           | Type    | Description |
|---------------------|---------|-------------|
| `author.created_at` | string  | Date and time when the author account was created. |
| `author.email`      | string  | Email address of the snippet author. |
| `author.id`         | integer | ID of the snippet author. |
| `author.name`       | string  | Display name of the snippet author. |
| `author.state`      | string  | State of the author account. |
| `author.username`   | string  | Username of the snippet author. |
| `created_at`        | string  | Date and time when the snippet was created in ISO 8601 format. |
| `description`       | string  | Description of the snippet. |
| `file_name`         | string  | Name of the snippet file. |
| `id`                | integer | ID of the snippet. |
| `imported`          | boolean | If `true`, the snippet was imported. |
| `imported_from`     | string  | Source of the import if the snippet was imported. |
| `project_id`        | integer | ID of the project containing the snippet. |
| `raw_url`           | string  | Direct URL to the raw snippet content. |
| `title`             | string  | Title of the snippet. |
| `updated_at`        | string  | Date and time when the snippet was last updated in ISO 8601 format. |
| `web_url`           | string  | URL to view the snippet in the GitLab web interface. |

Example request:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"title": "Updated Snippet Title", "description": "More verbose snippet description", "visibility": "private", "files": [{"action": "update", "file_path": "example.txt", "content": "updated source code \n with multiple lines\n"}]}' \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2"
```

Example response:

```json
{
  "id": 2,
  "title": "Updated Snippet Title",
  "file_name": "example.txt",
  "description": "More verbose snippet description",
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
  "imported": false,
  "imported_from": "none",
  "project_id": 1,
  "web_url": "http://example.com/example/example/snippets/2",
  "raw_url": "http://example.com/example/example/snippets/2/raw"
}
```

## Delete snippet

Deletes an existing project snippet. This returns a `204 No Content` status code if the operation was successfully or `404` if the resource was not found.

```plaintext
DELETE /projects/:id/snippets/:snippet_id
```

Supported attributes:

| Attribute    | Type              | Required | Description |
|--------------|-------------------|----------|-------------|
| `id`         | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `snippet_id` | integer           | Yes      | ID of a project's snippet. |

Example request:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2"
```

## Snippet content

Returns the raw project snippet as plain text.

```plaintext
GET /projects/:id/snippets/:snippet_id/raw
```

Supported attributes:

| Attribute    | Type              | Required | Description |
|--------------|-------------------|----------|-------------|
| `id`         | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `snippet_id` | integer           | Yes      | ID of a project's snippet. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2/raw"
```

## Snippet repository file content

Returns the raw file content as plain text.

```plaintext
GET /projects/:id/snippets/:snippet_id/files/:ref/:file_path/raw
```

Supported attributes:

| Attribute    | Type              | Required | Description |
|--------------|-------------------|----------|-------------|
| `id`         | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `file_path`  | string            | Yes      | URL-encoded path to the file, for example, `snippet%2Erb`. |
| `ref`        | string            | Yes      | Name of a branch, tag or commit, for example, `main`. |
| `snippet_id` | integer           | Yes      | ID of a project's snippet. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2/files/master/snippet%2Erb/raw"
```

## Get user agent details

Available only for users with administrator access.

```plaintext
GET /projects/:id/snippets/:snippet_id/user_agent_detail
```

Supported attributes:

| Attribute    | Type              | Required | Description |
|--------------|-------------------|----------|-------------|
| `id`         | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `snippet_id` | integer           | Yes      | ID of a snippet. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute           | Type    | Description |
|---------------------|---------|-------------|
| `akismet_submitted` | boolean | If `true`, the snippet was submitted to Akismet for spam detection. |
| `ip_address`        | string  | IP address of the user who created the snippet. |
| `user_agent`        | string  | User agent string of the browser used to create the snippet. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2/user_agent_detail"
```

Example response:

```json
{
  "user_agent": "AppleWebKit/537.36",
  "ip_address": "127.0.0.1",
  "akismet_submitted": false
}
```

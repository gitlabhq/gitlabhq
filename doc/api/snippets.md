---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Snippets API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to manage [snippets](../user/snippets.md). Related APIs exist for
[project snippets](project_snippets.md) and
[moving snippets between storages](snippet_repository_storage_moves.md).

## Snippet visibility level

Snippets in GitLab can be either private, internal, or public.
You can set it with the `visibility` field in the snippet.

Valid values for snippet visibility levels are:

| Visibility | Description                                         |
|-----------|---------------------------------------------------|
| `private`  | Snippet is visible only to the snippet creator.     |
| `internal` | Snippet is visible for any authenticated user except [external users](../administration/external_users.md).          |
| `public`   | Snippet can be accessed without any authentication. |

## List all snippets for current user

Get a list of the current user's snippets.

```plaintext
GET /snippets
```

Supported attributes:

| Attribute        | Type     | Required | Description |
|------------------|----------|----------|-------------|
| `created_after`  | datetime | No       | Return snippets created after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `created_before` | datetime | No       | Return snippets created before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `page`           | integer  | No       | Page to retrieve. |
| `per_page`       | integer  | No       | Number of snippets to return per page. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute       | Type    | Description |
|-----------------|---------|-------------|
| `author`        | object  | User object representing snippet author. |
| `created_at`    | string  | Date and time when snippet was created. |
| `description`   | string  | Description of snippet. |
| `file_name`     | string  | Name of snippet file. |
| `id`            | integer | ID of snippet. |
| `imported`      | boolean | If `true`, the snippet was imported. |
| `imported_from` | string  | Source of import. |
| `project_id`    | integer | ID of associated project. For personal snippets, `null`. |
| `raw_url`       | string  | URL to raw snippet content. |
| `title`         | string  | Title of snippet. |
| `updated_at`    | string  | Date and time when snippet was last updated. |
| `visibility`    | string  | Visibility level of snippet. |
| `web_url`       | string  | URL to snippet in GitLab UI. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets"
```

Example response:

```json
[
    {
        "id": 42,
        "title": "Voluptatem iure ut qui aut et consequatur quaerat.",
        "file_name": "mclaughlin.rb",
        "description": null,
        "visibility": "internal",
        "imported": false,
        "imported_from": "none",
        "author": {
            "id": 22,
            "name": "User 0",
            "username": "user0",
            "state": "active",
            "avatar_url": "https://www.gravatar.com/avatar/52e4ce24a915fb7e51e1ad3b57f4b00a?s=80&d=identicon",
            "web_url": "http://example.com/user0"
        },
        "updated_at": "2018-09-18T01:12:26.383Z",
        "created_at": "2018-09-18T01:12:26.383Z",
        "project_id": null,
        "web_url": "http://example.com/snippets/42",
        "raw_url": "http://example.com/snippets/42/raw"
    },
    {
        "id": 41,
        "title": "Ut praesentium non et atque.",
        "file_name": "ondrickaemard.rb",
        "description": null,
        "visibility": "internal",
        "imported": false,
        "imported_from": "none",
        "author": {
            "id": 22,
            "name": "User 0",
            "username": "user0",
            "state": "active",
            "avatar_url": "https://www.gravatar.com/avatar/52e4ce24a915fb7e51e1ad3b57f4b00a?s=80&d=identicon",
            "web_url": "http://example.com/user0"
        },
        "updated_at": "2018-09-18T01:12:26.360Z",
        "created_at": "2018-09-18T01:12:26.360Z",
        "project_id": 1,
        "web_url": "http://example.com/gitlab-org/gitlab-test/snippets/41",
        "raw_url": "http://example.com/gitlab-org/gitlab-test/snippets/41/raw"
    }
]
```

## Get a single snippet

Get a single snippet.

```plaintext
GET /snippets/:id
```

Supported attributes:

| Attribute | Type    | Required | Description                |
|-----------|---------|----------|----------------------------|
| `id`      | integer | Yes      | ID of snippet to retrieve. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute          | Type    | Description |
|--------------------|---------|-------------|
| `author`           | object  | User object representing snippet author. |
| `created_at`       | string  | Date and time when snippet was created. |
| `description`      | string  | Description of snippet. |
| `expires_at`       | string  | Date and time when snippet expires. |
| `file_name`        | string  | Name of snippet file. |
| `http_url_to_repo` | string  | HTTP URL to snippet repository. |
| `id`               | integer | ID of snippet. |
| `imported`         | boolean | If `true`, the snippet was imported. |
| `imported_from`    | string  | Source of import. |
| `project_id`       | integer | ID of associated project. For personal snippets, `null`. |
| `raw_url`          | string  | URL to raw snippet content. |
| `ssh_url_to_repo`  | string  | SSH URL to snippet repository. |
| `title`            | string  | Title of snippet. |
| `updated_at`       | string  | Date and time when snippet was last updated. |
| `visibility`       | string  | Visibility level of snippet. |
| `web_url`          | string  | URL to snippet in GitLab UI. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1"
```

Example response:

```json
{
  "id": 1,
  "title": "test",
  "file_name": "add.rb",
  "description": "Ruby test snippet",
  "visibility": "private",
  "imported": false,
  "imported_from": "none",
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
  "project_id": null,
  "web_url": "http://example.com/snippets/1",
  "raw_url": "http://example.com/snippets/1/raw"
}
```

## Single snippet contents

Get a single snippet's raw contents.

```plaintext
GET /snippets/:id/raw
```

Supported attributes:

| Attribute | Type    | Required | Description                |
|-----------|---------|----------|----------------------------|
| `id`      | integer | Yes      | ID of snippet to retrieve. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the raw content of the snippet.

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1/raw"
```

Example response:

```plaintext
Hello World snippet
```

## Snippet repository file content

Returns the raw file content as plain text.

```plaintext
GET /snippets/:id/files/:ref/:file_path/raw
```

Supported attributes:

| Attribute   | Type    | Required | Description |
|-------------|---------|----------|-------------|
| `file_path` | string  | Yes      | URL-encoded path to file. |
| `id`        | integer | Yes      | ID of snippet to retrieve. |
| `ref`       | string  | Yes      | Reference to a tag, branch or commit. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the raw file content.

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1/files/main/snippet%2Erb/raw"
```

Example response:

```plaintext
Hello World snippet
```

## Create new snippet

Create a new snippet.

{{< alert type="note" >}}

User must have permission to create new snippets.

{{< /alert >}}

```plaintext
POST /snippets
```

Supported attributes:

| Attribute         | Type            | Required | Description |
|-------------------|-----------------|----------|-------------|
| `files:content`   | string          | Yes      | Content of snippet file. |
| `files:file_path` | string          | Yes      | File path of snippet file. |
| `title`           | string          | Yes      | Title of a snippet. |
| `content`         | string          | No       | Deprecated: Use `files` instead. Content of a snippet. |
| `description`     | string          | No       | Description of a snippet. |
| `file_name`       | string          | No       | Deprecated: Use `files` instead. Name of a snippet file. |
| `files`           | array of hashes | No       | An array of snippet files. |
| `visibility`      | string          | No       | Snippet's [visibility](#snippet-visibility-level). |

If successful, returns [`201 Created`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute          | Type    | Description |
|--------------------|---------|-------------|
| `author`           | object  | User object representing snippet author. |
| `created_at`       | string  | Date and time when snippet was created. |
| `description`      | string  | Description of snippet. |
| `expires_at`       | string  | Date and time when snippet expires. |
| `file_name`        | string  | Name of snippet file. |
| `files`            | array   | Array of snippet files. |
| `http_url_to_repo` | string  | HTTP URL to snippet repository. |
| `id`               | integer | ID of snippet. |
| `imported`         | boolean | If `true`, the snippet was imported. |
| `imported_from`    | string  | Source of import. |
| `project_id`       | integer | ID of associated project. For personal snippets, `null`. |
| `raw_url`          | string  | URL to raw snippet content. |
| `ssh_url_to_repo`  | string  | SSH URL to snippet repository. |
| `title`            | string  | Title of snippet. |
| `updated_at`       | string  | Date and time when snippet was last updated. |
| `visibility`       | string  | Visibility level of snippet. |
| `web_url`          | string  | URL to snippet in GitLab UI. |

Example request:

```shell
curl --request POST "https://gitlab.example.com/api/v4/snippets" \
     --header 'Content-Type: application/json' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     -d @snippet.json
```

`snippet.json` used in the previous example request:

```json
{
  "title": "This is a snippet",
  "description": "Hello World snippet",
  "visibility": "internal",
  "files": [
    {
      "content": "Hello world",
      "file_path": "test.txt"
    }
  ]
}
```

Example response:

```json
{
  "id": 1,
  "title": "This is a snippet",
  "description": "Hello World snippet",
  "visibility": "internal",
  "imported": false,
  "imported_from": "none",
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
  "project_id": null,
  "web_url": "http://example.com/snippets/1",
  "raw_url": "http://example.com/snippets/1/raw",
  "ssh_url_to_repo": "ssh://git@gitlab.example.com:snippets/1.git",
  "http_url_to_repo": "https://gitlab.example.com/snippets/1.git",
  "file_name": "test.txt",
  "files": [
    {
      "path": "text.txt",
      "raw_url": "https://gitlab.example.com/-/snippets/1/raw/main/renamed.md"
    }
  ]
}
```

## Update snippet

Update an existing snippet.

{{< alert type="note" >}}

User must have permission to change an existing snippet.

{{< /alert >}}

```plaintext
PUT /snippets/:id
```

Supported attributes:

| Attribute             | Type            | Required      | Description |
|-----------------------|-----------------|---------------|-------------|
| `id`                  | integer         | Yes           | ID of snippet to update. |
| `files:action`        | string          | Yes           | Type of action to perform on file, one of: `create`, `update`, `delete`, `move`. |
| `content`             | string          | No            | Deprecated: Use `files` instead. Content of a snippet. |
| `description`         | string          | No            | Description of a snippet. |
| `file_name`           | string          | No            | Deprecated: Use `files` instead. Name of a snippet file. |
| `files`               | array of hashes | Conditionally | An array of snippet files. Required when updating snippets with multiple files. |
| `files:content`       | string          | No            | Content of snippet file. |
| `files:file_path`     | string          | No            | File path of snippet file. |
| `files:previous_path` | string          | No            | Previous path of snippet file. |
| `title`               | string          | No            | Title of a snippet. |
| `visibility`          | string          | No            | Snippet's [visibility](#snippet-visibility-level). |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute          | Type    | Description |
|--------------------|---------|-------------|
| `author`           | object  | User object representing snippet author. |
| `created_at`       | string  | Date and time when snippet was created. |
| `description`      | string  | Description of snippet. |
| `expires_at`       | string  | Date and time when snippet expires. |
| `file_name`        | string  | Name of snippet file. |
| `files`            | array   | Array of snippet files. |
| `http_url_to_repo` | string  | HTTP URL to snippet repository. |
| `id`               | integer | ID of snippet. |
| `imported`         | boolean | If `true`, the snippet was imported. |
| `imported_from`    | string  | Source of import. |
| `project_id`       | integer | ID of associated project. For personal snippets, `null`. |
| `raw_url`          | string  | URL to raw snippet content. |
| `ssh_url_to_repo`  | string  | SSH URL to snippet repository. |
| `title`            | string  | Title of snippet. |
| `updated_at`       | string  | Date and time when snippet was last updated. |
| `visibility`       | string  | Visibility level of snippet. |
| `web_url`          | string  | URL to snippet in GitLab UI. |

Example request:

```shell
curl --request PUT "https://gitlab.example.com/api/v4/snippets/1" \
     --header 'Content-Type: application/json' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     -d @snippet.json
```

`snippet.json` used in the previous example request:

```json
{
  "title": "foo",
  "files": [
    {
      "action": "move",
      "previous_path": "test.txt",
      "file_path": "renamed.md"
    }
  ]
}
```

Example response:

```json
{
  "id": 1,
  "title": "test",
  "description": "description of snippet",
  "visibility": "internal",
  "imported": false,
  "imported_from": "none",
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
  "project_id": null,
  "web_url": "http://example.com/snippets/1",
  "raw_url": "http://example.com/snippets/1/raw",
  "ssh_url_to_repo": "ssh://git@gitlab.example.com:snippets/1.git",
  "http_url_to_repo": "https://gitlab.example.com/snippets/1.git",
  "file_name": "renamed.md",
  "files": [
    {
      "path": "renamed.md",
      "raw_url": "https://gitlab.example.com/-/snippets/1/raw/main/renamed.md"
    }
  ]
}
```

## Delete snippet

Delete an existing snippet.

```plaintext
DELETE /snippets/:id
```

Supported attributes:

| Attribute | Type    | Required | Description              |
|-----------|---------|----------|--------------------------|
| `id`      | integer | Yes      | ID of snippet to delete. |

Example request:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1"
```

The following are possible return codes:

| Code  | Description |
|-------|-------------|
| `204` | Delete was successful. No data is returned. |
| `404` | Snippet wasn't found. |

## List all public snippets

List all public snippets.

```plaintext
GET /snippets/public
```

Supported attributes:

| Attribute        | Type     | Required | Description |
|------------------|----------|----------|-------------|
| `created_after`  | datetime | No       | Return snippets created after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `created_before` | datetime | No       | Return snippets created before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `page`           | integer  | No       | Page to retrieve. |
| `per_page`       | integer  | No       | Number of snippets to return per page. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute     | Type    | Description |
|---------------|---------|-------------|
| `author`      | object  | User object representing snippet author. |
| `created_at`  | string  | Date and time when snippet was created. |
| `description` | string  | Description of snippet. |
| `file_name`   | string  | Name of snippet file. |
| `id`          | integer | ID of snippet. |
| `project_id`  | integer | ID of associated project. For personal snippets, `null`. |
| `raw_url`     | string  | URL to raw snippet content. |
| `title`       | string  | Title of snippet. |
| `updated_at`  | string  | Date and time when snippet was last updated. |
| `visibility`  | string  | Visibility level of snippet. |
| `web_url`     | string  | URL to snippet in GitLab UI. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/public?per_page=2&page=1"
```

Example response:

```json
[
    {
        "author": {
            "avatar_url": "http://www.gravatar.com/avatar/edaf55a9e363ea263e3b981d09e0f7f7?s=80&d=identicon",
            "id": 12,
            "name": "Libby Rolfson",
            "state": "active",
            "username": "elton_wehner",
            "web_url": "http://example.com/elton_wehner"
        },
        "created_at": "2016-11-25T16:53:34.504Z",
        "file_name": "oconnerrice.rb",
        "id": 49,
        "title": "Ratione cupiditate et laborum temporibus.",
        "updated_at": "2016-11-25T16:53:34.504Z",
        "project_id": null,
        "web_url": "http://example.com/snippets/49",
        "raw_url": "http://example.com/snippets/49/raw"
    },
    {
        "author": {
            "avatar_url": "http://www.gravatar.com/avatar/36583b28626de71061e6e5a77972c3bd?s=80&d=identicon",
            "id": 16,
            "name": "Llewellyn Flatley",
            "state": "active",
            "username": "adaline",
            "web_url": "http://example.com/adaline"
        },
        "created_at": "2016-11-25T16:53:34.479Z",
        "file_name": "muellershields.rb",
        "id": 48,
        "title": "Minus similique nesciunt vel fugiat qui ullam sunt.",
        "updated_at": "2016-11-25T16:53:34.479Z",
        "project_id": null,
        "web_url": "http://example.com/snippets/48",
        "raw_url": "http://example.com/snippets/49/raw",
        "visibility": "public"
    }
]
```

## List all snippets

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/419640) in GitLab 16.3.

{{< /history >}}

List all snippets the current user has access to.
Users with the Administrator or Auditor access levels can see all snippets
(both personal and project).

```plaintext
GET /snippets/all
```

Supported attributes:

| Attribute            | Type     | Required | Description |
|----------------------|----------|----------|-------------|
| `created_after`      | datetime | No       | Return snippets created after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `created_before`     | datetime | No       | Return snippets created before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `page`               | integer  | No       | Page to retrieve. |
| `per_page`           | integer  | No       | Number of snippets to return per page. |
| `repository_storage` | string   | No       | Filter by repository storage used by snippet _(administrators only)_. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/419640) in GitLab 16.3. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute            | Type    | Description |
|----------------------|---------|-------------|
| `author`             | object  | User object representing snippet author. |
| `created_at`         | string  | Date and time when snippet was created. |
| `description`        | string  | Description of snippet. |
| `file_name`          | string  | Name of snippet file. |
| `files`              | array   | Array of snippet files. |
| `id`                 | integer | ID of snippet. |
| `imported`           | boolean | If `true`, the snippet was imported. |
| `imported_from`      | string  | Source of import. |
| `project_id`         | integer | ID of associated project. For personal snippets, `null`. |
| `raw_url`            | string  | URL to raw snippet content. |
| `repository_storage` | string  | Repository storage used by snippet. |
| `title`              | string  | Title of snippet. |
| `updated_at`         | string  | Date and time when snippet was last updated. |
| `visibility`         | string  | Visibility level of snippet. |
| `web_url`            | string  | URL to snippet in GitLab UI. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/all?per_page=2&page=1"
```

Example response:

```json
[
  {
    "id": 113,
    "title": "Internal Project Snippet",
    "description": null,
    "visibility": "internal",
    "imported": false,
    "imported_from": "none",
    "author": {
      "id": 17,
      "username": "tim_kreiger",
      "name": "Tim Kreiger",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/edaf55a9e363ea263e3b981d09e0f7f7?s=80&d=identicon",
      "web_url": "http://example.com/tim_kreiger"
    },
    "created_at": "2023-08-03T10:21:02.480Z",
    "updated_at": "2023-08-03T10:21:02.480Z",
    "project_id": 35,
    "web_url": "http://example.com/tim_kreiger/internal_project/-/snippets/113",
    "raw_url": "http://example.com/tim_kreiger/internal_project/-/snippets/113/raw",
    "file_name": "",
    "files": [],
    "repository_storage": "default"
  },
  {
    "id": 112,
    "title": "Private Personal Snippet",
    "description": null,
    "visibility": "private",
    "imported": false,
    "imported_from": "none",
    "author": {
      "id": 1,
      "username": "root",
      "name": "Administrator",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/edaf55a9e363ea263e3b981d09e0f7f7?s=80&d=identicon",
      "web_url": "http://example.com/root"
    },
    "created_at": "2023-08-03T10:20:59.994Z",
    "updated_at": "2023-08-03T10:20:59.994Z",
    "project_id": null,
    "web_url": "http://example.com/-/snippets/112",
    "raw_url": "http://example.com/-/snippets/112/raw",
    "file_name": "",
    "files": [],
    "repository_storage": "default"
  },
  {
    "id": 111,
    "title": "Public Personal Snippet",
    "description": null,
    "visibility": "public",
    "imported": false,
    "imported_from": "none",
    "author": {
      "id": 17,
      "username": "tim_kreiger",
      "name": "Tim Kreiger",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/edaf55a9e363ea263e3b981d09e0f7f7?s=80&d=identicon",
      "web_url": "http://example.com/tim_kreiger"
    },
    "created_at": "2023-08-03T10:21:01.312Z",
    "updated_at": "2023-08-03T10:21:01.312Z",
    "project_id": null,
    "web_url": "http://example.com/-/snippets/111",
    "raw_url": "http://example.com/-/snippets/111/raw",
    "file_name": "",
    "files": [],
    "repository_storage": "default"
  }
]
```

## Get user agent details

{{< alert type="note" >}}

Available only for administrators.

{{< /alert >}}

```plaintext
GET /snippets/:id/user_agent_detail
```

Supported attributes:

| Attribute | Type    | Required | Description    |
|-----------|---------|----------|----------------|
| `id`      | integer | Yes      | ID of snippet. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute           | Type    | Description |
|---------------------|---------|-------------|
| `akismet_submitted` | boolean | If `true`, the details were submitted to Akismet. |
| `ip_address`        | string  | IP address used to create snippet. |
| `user_agent`        | string  | User agent string used to create snippet. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1/user_agent_detail"
```

Example response:

```json
{
  "user_agent": "AppleWebKit/537.36",
  "ip_address": "127.0.0.1",
  "akismet_submitted": false
}
```

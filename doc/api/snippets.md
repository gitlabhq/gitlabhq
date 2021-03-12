---
stage: Create
group: Editor
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, api
---

# Snippets API **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/6373) in GitLab 8.15.

Snippets API operates on [snippets](../user/snippets.md). Related APIs exist for
[project snippets](project_snippets.md) and
[moving snippets between storages](snippet_repository_storage_moves.md).

## Snippet visibility level

Snippets in GitLab can be either private, internal, or public.
You can set it with the `visibility` field in the snippet.

Valid values for snippet visibility levels are:

| Visibility | Description                                         |
|:-----------|:----------------------------------------------------|
| `private`  | Snippet is visible only to the snippet creator.     |
| `internal` | Snippet is visible for any logged in user except [external users](../user/permissions.md#external-users).          |
| `public`   | Snippet can be accessed without any authentication. |

## List all snippets for a user

Get a list of the current user's snippets.

```plaintext
GET /snippets
```

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/snippets"
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

Parameters:

| Attribute | Type    | Required | Description                |
|:----------|:--------|:---------|:---------------------------|
| `id`      | integer | yes      | ID of snippet to retrieve. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/snippets/1"
```

Example response:

```json
{
  "id": 1,
  "title": "test",
  "file_name": "add.rb",
  "description": "Ruby test snippet",
  "visibility": "private",
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

Parameters:

| Attribute | Type    | Required | Description                |
|:----------|:--------|:---------|:---------------------------|
| `id`      | integer | yes      | ID of snippet to retrieve. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/snippets/1/raw"
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

Parameters:

| Attribute   | Type    | Required | Description                                                        |
|:------------|:--------|:---------|:-------------------------------------------------------------------|
| `id`        | integer | yes      | ID of snippet to retrieve.                                         |
| `ref`       | string  | yes      | Reference to a tag, branch or commit.                              |
| `file_path` | string  | yes      | URL-encoded path to the file.                                      |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/snippets/1/files/master/snippet%2Erb/raw"
```

Example response:

```plaintext
Hello World snippet
```

## Create new snippet

Create a new snippet.

NOTE:
The user must have permission to create new snippets.

```plaintext
POST /snippets
```

Parameters:

| Attribute         | Type            | Required | Description                                             |
|:------------------|:----------------|:---------|:--------------------------------------------------------|
| `title`           | string          | yes      | Title of a snippet                                      |
| `file_name`       | string          | no       | Deprecated: Use `files` instead. Name of a snippet file |
| `content`         | string          | no       | Deprecated: Use `files` instead. Content of a snippet   |
| `description`     | string          | no       | Description of a snippet                                |
| `visibility`      | string          | no       | Snippet's [visibility](#snippet-visibility-level)       |
| `files`           | array of hashes | no       | An array of snippet files                               |
| `files:file_path` | string          | yes      | File path of the snippet file                           |
| `files:content`   | string          | yes      | Content of the snippet file                             |

Example request:

```shell
curl --request POST "https://gitlab.example.com/api/v4/snippets" \
     --header 'Content-Type: application/json' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     -d @snippet.json
```

`snippet.json` used in the above example request:

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
      "raw_url": "https://gitlab.example.com/-/snippets/1/raw/master/renamed.md"
    }
  ]
}
```

## Update snippet

Update an existing snippet.

NOTE:
The user must have permission to change an existing snippet.

```plaintext
PUT /snippets/:id
```

Parameters:

| Attribute             | Type            | Required | Description                                                                         |
|:----------------------|:----------------|:---------|:------------------------------------------------------------------------------------|
| `id`                  | integer         | yes      | ID of snippet to update                                                             |
| `title`               | string          | no       | Title of a snippet                                                                  |
| `file_name`           | string          | no       | Deprecated: Use `files` instead. Name of a snippet file                             |
| `content`             | string          | no       | Deprecated: Use `files` instead. Content of a snippet                               |
| `description`         | string          | no       | Description of a snippet                                                            |
| `visibility`          | string          | no       | Snippet's [visibility](#snippet-visibility-level)                                   |
| `files`               | array of hashes | sometimes | An array of snippet files. Required when updating snippets with multiple files. |
| `files:action`        | string          | yes      | Type of action to perform on the file, one of: `create`, `update`, `delete`, `move` |
| `files:file_path`     | string          | no       | File path of the snippet file                                                       |
| `files:previous_path` | string          | no       | Previous path of the snippet file                                                   |
| `files:content`       | string          | no       | Content of the snippet file                                                         |

Example request:

```shell
curl --request PUT "https://gitlab.example.com/api/v4/snippets/1" \
     --header 'Content-Type: application/json' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     -d @snippet.json
```

`snippet.json` used in the above example request:

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
      "raw_url": "https://gitlab.example.com/-/snippets/1/raw/master/renamed.md"
    }
  ]
}
```

## Delete snippet

Delete an existing snippet.

```plaintext
DELETE /snippets/:id
```

Parameters:

| Attribute | Type    | Required | Description              |
|:----------|:--------|:---------|:-------------------------|
| `id`      | integer | yes      | ID of snippet to delete. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/snippets/1"
```

The following are possible return codes:

| Code  | Description                                 |
|:------|:--------------------------------------------|
| `204` | Delete was successful. No data is returned. |
| `404` | The snippet wasn't found.                   |

## List all public snippets

List all public snippets.

```plaintext
GET /snippets/public
```

Parameters:

| Attribute  | Type    | Required | Description                            |
|:-----------|:--------|:---------|:---------------------------------------|
| `per_page` | integer | no       | Number of snippets to return per page. |
| `page`     | integer | no       | Page to retrieve.                      |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/snippets/public?per_page=2&page=1"
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

## Get user agent details

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/12655) in GitLab 9.4.

NOTE:
Available only for administrators.

```plaintext
GET /snippets/:id/user_agent_detail
```

| Attribute | Type    | Required | Description    |
|:----------|:--------|:---------|:---------------|
| `id`      | integer | yes      | ID of snippet. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/snippets/1/user_agent_detail"
```

Example response:

```json
{
  "user_agent": "AppleWebKit/537.36",
  "ip_address": "127.0.0.1",
  "akismet_submitted": false
}
```

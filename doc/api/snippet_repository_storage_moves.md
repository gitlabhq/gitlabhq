---
stage: Create
group: Editor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Snippet repository storage moves API **(FREE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49228) in GitLab 13.8.

Snippet repositories can be moved between storages. This can be useful when
[migrating to Gitaly Cluster](../administration/gitaly/praefect.md#migrate-to-gitaly-cluster), for
example.

As snippet repository storage moves are processed, they transition through different states. Values
of `state` are:

- `initial`
- `scheduled`
- `started`
- `finished`
- `failed`
- `replicated`
- `cleanup failed`

To ensure data integrity, snippets are put in a temporary read-only state for the
duration of the move. During this time, users receive a `The repository is temporarily
read-only. Please try again later.` message if they try to push new commits.

This API requires you to [authenticate yourself](README.md#authentication) as an administrator.

For other repository types see:

- [Project repository storage moves API](project_repository_storage_moves.md).
- [Group repository storage moves API](group_repository_storage_moves.md).

## Retrieve all snippet repository storage moves

```plaintext
GET /snippet_repository_storage_moves
```

By default, `GET` requests return 20 results at a time because the API results
are [paginated](README.md#pagination).

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/snippet_repository_storage_moves"
```

Example response:

```json
[
  {
    "id": 1,
    "created_at": "2020-05-07T04:27:17.234Z",
    "state": "scheduled",
    "source_storage_name": "default",
    "destination_storage_name": "storage2",
    "snippet": {
      "id": 65,
      "title": "Test Snippet",
      "description": null,
      "visibility": "internal",
      "updated_at": "2020-12-01T11:15:50.385Z",
      "created_at": "2020-12-01T11:15:50.385Z",
      "project_id": null,
      "web_url": "https://gitlab.example.com/-/snippets/65",
      "raw_url": "https://gitlab.example.com/-/snippets/65/raw",
      "ssh_url_to_repo": "ssh://user@gitlab.example.com/snippets/65.git",
      "http_url_to_repo": "https://gitlab.example.com/snippets/65.git"
    }
  }
]
```

## Retrieve all repository storage moves for a snippet

```plaintext
GET /snippets/:snippet_id/repository_storage_moves
```

By default, `GET` requests return 20 results at a time because the API results
are [paginated](README.md#pagination).

Supported attributes:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `snippet_id` | integer | yes | ID of the snippet. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/snippets/1/repository_storage_moves"
```

Example response:

```json
[
  {
    "id": 1,
    "created_at": "2020-05-07T04:27:17.234Z",
    "state": "scheduled",
    "source_storage_name": "default",
    "destination_storage_name": "storage2",
    "snippet": {
      "id": 65,
      "title": "Test Snippet",
      "description": null,
      "visibility": "internal",
      "updated_at": "2020-12-01T11:15:50.385Z",
      "created_at": "2020-12-01T11:15:50.385Z",
      "project_id": null,
      "web_url": "https://gitlab.example.com/-/snippets/65",
      "raw_url": "https://gitlab.example.com/-/snippets/65/raw",
      "ssh_url_to_repo": "ssh://user@gitlab.example.com/snippets/65.git",
      "http_url_to_repo": "https://gitlab.example.com/snippets/65.git"
    }
  }
]
```

## Get a single snippet repository storage move

```plaintext
GET /snippet_repository_storage_moves/:repository_storage_id
```

Supported attributes:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `repository_storage_id` | integer | yes | ID of the snippet repository storage move. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/snippet_repository_storage_moves/1"
```

Example response:

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "snippet": {
    "id": 65,
    "title": "Test Snippet",
    "description": null,
    "visibility": "internal",
    "updated_at": "2020-12-01T11:15:50.385Z",
    "created_at": "2020-12-01T11:15:50.385Z",
    "project_id": null,
    "web_url": "https://gitlab.example.com/-/snippets/65",
    "raw_url": "https://gitlab.example.com/-/snippets/65/raw",
    "ssh_url_to_repo": "ssh://user@gitlab.example.com/snippets/65.git",
    "http_url_to_repo": "https://gitlab.example.com/snippets/65.git"
  }
}
```

## Get a single repository storage move for a snippet

```plaintext
GET /snippets/:snippet_id/repository_storage_moves/:repository_storage_id
```

Supported attributes:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `snippet_id` | integer | yes | ID of the snippet. |
| `repository_storage_id` | integer | yes | ID of the snippet repository storage move. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/snippets/1/repository_storage_moves/1"
```

Example response:

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "snippet": {
    "id": 65,
    "title": "Test Snippet",
    "description": null,
    "visibility": "internal",
    "updated_at": "2020-12-01T11:15:50.385Z",
    "created_at": "2020-12-01T11:15:50.385Z",
    "project_id": null,
    "web_url": "https://gitlab.example.com/-/snippets/65",
    "raw_url": "https://gitlab.example.com/-/snippets/65/raw",
    "ssh_url_to_repo": "ssh://user@gitlab.example.com/snippets/65.git",
    "http_url_to_repo": "https://gitlab.example.com/snippets/65.git"
  }
}
```

## Schedule a repository storage move for a snippet

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49228) in GitLab 13.8.

```plaintext
POST /snippets/:snippet_id/repository_storage_moves
```

Supported attributes:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `snippet_id` | integer | yes | ID of the snippet. |
| `destination_storage_name` | string | no | Name of the destination storage shard. In [GitLab 13.5 and later](https://gitlab.com/gitlab-org/gitaly/-/issues/3209), the storage is selected [automatically based on storage weights](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored) if not provided. |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" \
--data '{"destination_storage_name":"storage2"}' "https://gitlab.example.com/api/v4/snippets/1/repository_storage_moves"
```

Example response:

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "snippet": {
    "id": 65,
    "title": "Test Snippet",
    "description": null,
    "visibility": "internal",
    "updated_at": "2020-12-01T11:15:50.385Z",
    "created_at": "2020-12-01T11:15:50.385Z",
    "project_id": null,
    "web_url": "https://gitlab.example.com/-/snippets/65",
    "raw_url": "https://gitlab.example.com/-/snippets/65/raw",
    "ssh_url_to_repo": "ssh://user@gitlab.example.com/snippets/65.git",
    "http_url_to_repo": "https://gitlab.example.com/snippets/65.git"
  }
}
```

## Schedule repository storage moves for all snippets on a storage shard

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49228) in GitLab 13.8.

Schedules repository storage moves for each snippet repository stored on the source storage shard.

```plaintext
POST /snippet_repository_storage_moves
```

Supported attributes:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `source_storage_name` | string | yes | Name of the source storage shard. |
| `destination_storage_name` | string | no | Name of the destination storage shard. The storage is selected [automatically based on storage weights](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored) if not provided. |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" \
--data '{"source_storage_name":"default"}' "https://gitlab.example.com/api/v4/snippet_repository_storage_moves"
```

Example response:

```json
{
  "message": "202 Accepted"
}
```

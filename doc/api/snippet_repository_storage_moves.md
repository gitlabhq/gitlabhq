---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Snippet repository storage moves API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Snippet repositories can be moved between storages. This API can help you when
[migrating to Gitaly Cluster](../administration/gitaly/_index.md#migrate-to-gitaly-cluster), for
example.

As snippet repository storage moves are processed, they transition through different states. Values
of `state` are:

- `initial`: The record has been created but the background job has not yet been scheduled.
- `scheduled`: The background job has been scheduled.
- `started`: The snippet repository is being copied to the destination storage.
- `replicated`: The snippet has been moved.
- `failed`: The snippet repository failed to copy or the checksum did not match.
- `finished`: The snippet has been moved and the repository on the source storage has been deleted.
- `cleanup failed`: The snippet has been moved but the repository on the source storage could not be deleted.

To ensure data integrity, snippets are put in a temporary read-only state for the
duration of the move. During this time, users receive a `The repository is temporarily read-only. Please try again later.`
message if they try to push new commits.

This API requires you to [authenticate yourself](rest/authentication.md) as an administrator.

For other repository types see:

- [Project repository storage moves API](project_repository_storage_moves.md).
- [Group repository storage moves API](group_repository_storage_moves.md).

## Retrieve all snippet repository storage moves

```plaintext
GET /snippet_repository_storage_moves
```

By default, `GET` requests return 20 results at a time because the API results
are [paginated](rest/_index.md#pagination).

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippet_repository_storage_moves"
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
are [paginated](rest/_index.md#pagination).

Supported attributes:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `snippet_id` | integer | yes | ID of the snippet. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1/repository_storage_moves"
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
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippet_repository_storage_moves/1"
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
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1/repository_storage_moves/1"
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

```plaintext
POST /snippets/:snippet_id/repository_storage_moves
```

Supported attributes:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `snippet_id` | integer | yes | ID of the snippet. |
| `destination_storage_name` | string | no | Name of the destination storage shard. The storage is selected [automatically based on storage weights](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored) if not provided. |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"destination_storage_name":"storage2"}' \
     --url "https://gitlab.example.com/api/v4/snippets/1/repository_storage_moves"
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

Schedules repository storage moves for each snippet repository stored on the source storage shard.
This endpoint migrates all snippets at once. For more information, see
[Move all snippets](../administration/operations/moving_repositories.md#move-all-snippets).

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
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"source_storage_name":"default"}' \
     --url "https://gitlab.example.com/api/v4/snippet_repository_storage_moves"
```

Example response:

```json
{
  "message": "202 Accepted"
}
```

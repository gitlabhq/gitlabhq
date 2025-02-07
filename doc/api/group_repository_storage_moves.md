---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Documentation for the REST API for moving the storage for repositories in a GitLab group."
title: Group repository storage moves API
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Group wiki repositories can be moved between storages. This API can help you, for example,
[migrate to Gitaly Cluster](../administration/gitaly/_index.md#migrate-to-gitaly-cluster)
or migrate a [group wiki](../user/project/wiki/group.md). This API does not manage
project repositories in a group. To schedule project moves, use the
[project repository storage moves API](project_repository_storage_moves.md).

As GitLab processes a group repository storage move, it transitions through different states. Values
of `state` are:

- `initial`: The record has been created, but the background job has not yet been scheduled.
- `scheduled`: The background job has been scheduled.
- `started`: The group repositories are being copied to the destination storage.
- `replicated`: The group has been moved.
- `failed`: The group repositories failed to copy, or the checksums did not match.
- `finished`: The group has been moved, and the repositories on the source storage have been deleted.
- `cleanup failed`: The group has been moved, but the repositories on the source storage could not be deleted.

To ensure data integrity, GitLab places groups in a temporary read-only state for the
duration of the move. During this time, users receive this message if they try to
push new commits:

```plaintext
The repository is temporarily read-only. Please try again later.
```

This API requires you to [authenticate yourself](rest/authentication.md) as an administrator.

APIs are also available to move other types of repositories:

- [Project repository storage moves API](project_repository_storage_moves.md).
- [Snippet repository storage moves API](snippet_repository_storage_moves.md).

## Retrieve all group repository storage moves

```plaintext
GET /group_repository_storage_moves
```

By default, `GET` requests return 20 results at a time, because the API results
are [paginated](rest/_index.md#pagination).

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/group_repository_storage_moves"
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
    "group": {
      "id": 283,
      "web_url": "https://gitlab.example.com/groups/testgroup",
      "name": "testgroup"
    }
  }
]
```

## Retrieve all repository storage moves for a single group

To retrieve all the repository storage moves for a single group you can use the following endpoint:

```plaintext
GET /groups/:group_id/repository_storage_moves
```

By default, `GET` requests return 20 results at a time, because the API results
are [paginated](rest/_index.md#pagination).

Supported attributes:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `group_id` | integer | yes | ID of the group. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/repository_storage_moves"
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
    "group": {
      "id": 283,
      "web_url": "https://gitlab.example.com/groups/testgroup",
      "name": "testgroup"
    }
  }
]
```

## Get a single group repository storage move

To retrieve a single repository storage move throughout all the existing repository
storage moves, you can use the following endpoint:

```plaintext
GET /group_repository_storage_moves/:repository_storage_id
```

Supported attributes:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `repository_storage_id` | integer | yes | ID of the group repository storage move. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/group_repository_storage_moves/1"
```

Example response:

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "group": {
    "id": 283,
    "web_url": "https://gitlab.example.com/groups/testgroup",
    "name": "testgroup"
  }
}
```

## Get a single repository storage move for a group

Given a group, you can retrieve a specific repository storage move for that group,
through the following endpoint:

```plaintext
GET /groups/:group_id/repository_storage_moves/:repository_storage_id
```

Supported attributes:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `group_id` | integer | yes | ID of the group. |
| `repository_storage_id` | integer | yes | ID of the group repository storage move. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/repository_storage_moves/1"
```

Example response:

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "group": {
    "id": 283,
    "web_url": "https://gitlab.example.com/groups/testgroup",
    "name": "testgroup"
  }
}
```

## Schedule a repository storage move for a group

Schedules a repository storage move for a group. This endpoint:

- Moves only group Wiki repositories.
- Doesn't move repositories for projects in a group. To schedule project moves, use the [Project repository storage moves](project_repository_storage_moves.md) API.

```plaintext
POST /groups/:group_id/repository_storage_moves
```

Supported attributes:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `group_id` | integer | yes | ID of the group. |
| `destination_storage_name` | string | no | Name of the destination storage shard. The storage is selected [based on storage weights](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored) if not provided. |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"destination_storage_name":"storage2"}' \
     --url "https://gitlab.example.com/api/v4/groups/1/repository_storage_moves"
```

Example response:

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "group": {
    "id": 283,
    "web_url": "https://gitlab.example.com/groups/testgroup",
    "name": "testgroup"
  }
}
```

## Schedule repository storage moves for all groups on a storage shard

Schedules repository storage moves for each group repository stored on the source storage shard.
This endpoint migrates all groups at once. For more information, see
[Move all groups](../administration/operations/moving_repositories.md#move-all-groups).

```plaintext
POST /group_repository_storage_moves
```

Supported attributes:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `source_storage_name` | string | yes | Name of the source storage shard. |
| `destination_storage_name` | string | no | Name of the destination storage shard. The storage is selected [based on storage weights](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored) if not provided. |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"source_storage_name":"default"}' \
     --url "https://gitlab.example.com/api/v4/group_repository_storage_moves"
```

Example response:

```json
{
  "message": "202 Accepted"
}
```

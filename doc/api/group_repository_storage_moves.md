---
stage: Create
group: Editor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Group repository storage moves API **(PREMIUM SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/53016) in GitLab 13.9.

Group repositories can be moved between storages. This can be useful when
[migrating to Gitaly Cluster](../administration/gitaly/praefect.md#migrate-to-gitaly-cluster), for
example, or to migrate a Group Wiki.

As group repository storage moves are processed, they transition through different states. Values
of `state` are:

- `initial`: The record has been created but the background job has not yet been scheduled.
- `scheduled`: The background job has been scheduled.
- `started`: The group repositories are being copied to the destination storage.
- `replicated`: The group has been moved.
- `failed`: The group repositories failed to copy or the checksums did not match.
- `finished`: The group has been moved and the repositories on the source storage have been deleted.
- `cleanup failed`: The group has been moved but the repositories on the source storage could not be deleted.

To ensure data integrity, groups are put in a temporary read-only state for the
duration of the move. During this time, users receive a `The repository is temporarily
read-only. Please try again later.` message if they try to push new commits.

This API requires you to [authenticate yourself](index.md#authentication) as an administrator.

For other type of repositories you can read:

- [Project repository storage moves API](project_repository_storage_moves.md)
- [Snippet repository storage moves API](snippet_repository_storage_moves.md)

## Retrieve all group repository storage moves

```plaintext
GET /group_repository_storage_moves
```

By default, `GET` requests return 20 results at a time because the API results
are [paginated](index.md#pagination).

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/group_repository_storage_moves"
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

In order to retrieve all the repository storage moves for a single group you can use the following endpoint:

```plaintext
GET /groups/:group_id/repository_storage_moves
```

By default, `GET` requests return 20 results at a time because the API results
are [paginated](index.md#pagination).

Supported attributes:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `group_id` | integer | yes | ID of the group. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/repository_storage_moves"
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

In order to retrieve a single repository storage move throughout all the existing repository storage moves, you can use the following endpoint:

```plaintext
GET /group_repository_storage_moves/:repository_storage_id
```

Supported attributes:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `repository_storage_id` | integer | yes | ID of the group repository storage move. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/group_repository_storage_moves/1"
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

Given a group, you can retrieve a specific repository storage move for that group, through the following endpoint:

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
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/repository_storage_moves/1"
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

```plaintext
POST /groups/:group_id/repository_storage_moves
```

Supported attributes:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `group_id` | integer | yes | ID of the group. |
| `destination_storage_name` | string | no | Name of the destination storage shard. In [GitLab 13.5 and later](https://gitlab.com/gitlab-org/gitaly/-/issues/3209), the storage is selected [automatically based on storage weights](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored) if not provided. |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"destination_storage_name":"storage2"}' \
     "https://gitlab.example.com/api/v4/groups/1/repository_storage_moves"
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

```plaintext
POST /group_repository_storage_moves
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
     "https://gitlab.example.com/api/v4/group_repository_storage_moves"
```

Example response:

```json
{
  "message": "202 Accepted"
}
```

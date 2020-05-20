# Project repository storage move API

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/31285) in GitLab 13.0.

Project repository storage can be moved. To retrieve project repository storage moves using the API, you must [authenticate yourself](README.md#authentication) as an administrator.

## Retrieve all project repository storage moves

```plaintext
GET /project_repository_storage_moves
```

By default, `GET` requests return 20 results at a time because the API results
are [paginated](README.md#pagination).

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" 'https://primary.example.com/api/v4/project_repository_storage_moves'
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
    "project": {
      "id": 1,
      "description": null,
      "name": "project1",
      "name_with_namespace": "John Doe2 / project1",
      "path": "project1",
      "path_with_namespace": "namespace1/project1",
      "created_at": "2020-05-07T04:27:17.016Z"
  }
]
```

## Get a single project repository storage move

```plaintext
GET /project_repository_storage_moves/:id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the project repository storage move |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" 'https://primary.example.com/api/v4/project_repository_storage_moves/1'
```

Example response:

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "project": {
    "id": 1,
    "description": null,
    "name": "project1",
    "name_with_namespace": "John Doe2 / project1",
    "path": "project1",
    "path_with_namespace": "namespace1/project1",
    "created_at": "2020-05-07T04:27:17.016Z"
}
```

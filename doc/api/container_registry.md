# Container Registry API

## List registry repositories

Get a list of registry repositories in a project.

```
GET /projects/:id/registry/repositories
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user


```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "",
    "path": "group/project",
    "location": "gitlab.example.com:5000/group/project",
    "created_at": "2019-01-10T13:38:57.391Z"
  },
  {
    "id": 2,
    "name": "releases",
    "path": "group/project/releases",
    "location": "gitlab.example.com:5000/group/project/releases",
    "created_at": "2019-01-10T13:39:08.229Z"
  }
]
```

## Delete registry repository

Get a list of repository commits in a project.

This operation is executed asynchronously and it might take
time to get executed.

```
DELETE /projects/:id/registry/repositories/:repository_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
| `repository_id` | integer | yes | The ID of registry repository

```bash
curl -X DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2"
```

## List repository tags

Get a list of tags for given registry repository.

```
GET /projects/:id/registry/repositories/:repository_id/tags
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
| `repository_id` | integer | yes | The ID of registry repository

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
```

Example response:

```json
[
  {
    "name": "A",
    "path": "group/project:A",
    "location": "gitlab.example.com:5000/group/project:A"
  },
  {
    "name": "latest",
    "path": "group/project:latest",
    "location": "gitlab.example.com:5000/group/project:latest"
  }
]
```

## Delete repository tags (in bulk)

Delete repository tags in bulk based on given criteria.

This API performs a following set of the operations:

1. It schedules asynchronous job executed in background,
1. It never removes tag named `latest`,
1. It removes the tags matching given `name_regex` only,
1. It orders all tags by creation date. The creation date is time of the manifest creation. It is not a time of tag push,
1. It keeps N latest matching tags (if specified),
1. It only removes tags that are older than (if specified).

These operations are executed asynchronously and it might
take time to get executed. This API can be run at most
once an hour for given container repository.

Due to [Docker Distribution deficiency](ce-21405) it does
not remove tags whose manifest is shared by multiple tags

```
DELETE /projects/:id/registry/repositories/:repository_id/tags
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
| `repository_id` | integer | yes | The ID of registry repository
| `name_regex` | string | yes | The regex of the name to delete. To delete all tags specify `.*`
| `keep_n` | integer | no | The amount of latest tags of given name to keep
| `older_than` | string | no | Tags to delete that are older than given timespec, written in human readable form `1h`, `1d`, `1month` |

Examples:

1. Remove tag names that are matching GIT SHA, keep always at least 5, and remove ones that are older than 2 days:

    ```bash
    curl -X DELETE -F 'name_regex=[0-9a-z]{40}' -F 'keep_n=5' -F 'older_than=2d' --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
    ```

2. Remove all tags, but keep always latest 5:

    ```bash
    curl -X DELETE -F 'name_regex=.*' -F 'keep_n=5' --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
    ```

3. Remove all tags that are older than 1 month:

    ```bash
    curl -X DELETE -F 'name_regex=.*' -F 'older_than=1month' --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
    ```

## Get a details repository tag

Get a details of registry repository tag

```
GET /projects/:id/registry/repositories/:repository_id/tags/:tag_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
| `repository_id` | integer | yes | The ID of registry repository
| `tag_name` | string | yes | The name of tag

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags/v10.0.0"
```

Example response:

```json
{
  "name": "v10.0.0",
  "path": "group/project:latest",
  "location": "gitlab.example.com:5000/group/project:latest",
  "revision": "e9ed9d87c881d8c2fd3a31b41904d01ba0b836e7fd15240d774d811a1c248181",
  "short_revision": "e9ed9d87c",
  "digest": "sha256:c3490dcf10ffb6530c1303522a1405dfaf7daecd8f38d3e6a1ba19ea1f8a1751",
  "created_at": "2019-01-06T16:49:51.272+00:00",
  "total_size": 350224384
}
```

## Delete a repository tag

Delete a registry repository tag

```
DELETE /projects/:id/registry/repositories/:repository_id/tags/:tag_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
| `repository_id` | integer | yes | The ID of registry repository
| `tag_name` | string | yes | The name of tag

```bash
curl -X DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags/v10.0.0"
```

[ce-21405]: https://gitlab.com/gitlab-org/gitlab-ce/issues/21405

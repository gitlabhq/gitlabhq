# Container Registry API

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/55978) in GitLab 11.8.

This is the API docs of the [GitLab Container Registry](../user/project/container_registry.md).

## List registry repositories

Get a list of registry repositories in a project.

```
GET /projects/:id/registry/repositories
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |

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

Delete a repository in registry.

This operation is executed asynchronously and might take some time to get executed.

```
DELETE /projects/:id/registry/repositories/:repository_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
| `repository_id` | integer | yes | The ID of registry repository. |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2"
```

## List repository tags

Get a list of tags for given registry repository.

```
GET /projects/:id/registry/repositories/:repository_id/tags
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
| `repository_id` | integer | yes | The ID of registry repository. |

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

## Get details of a repository tag

Get details of a registry repository tag.

```
GET /projects/:id/registry/repositories/:repository_id/tags/:tag_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
| `repository_id` | integer | yes | The ID of registry repository. |
| `tag_name` | string | yes | The name of tag. |

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

Delete a registry repository tag.

```
DELETE /projects/:id/registry/repositories/:repository_id/tags/:tag_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
| `repository_id` | integer | yes | The ID of registry repository. |
| `tag_name` | string | yes | The name of tag. |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags/v10.0.0"
```

This action does not delete blobs. In order to delete them and recycle disk space,
[run the garbage collection](https://docs.gitlab.com/omnibus/maintenance/README.html#removing-unused-layers-not-referenced-by-manifests).

## Delete repository tags in bulk

Delete repository tags in bulk based on given criteria.

```
DELETE /projects/:id/registry/repositories/:repository_id/tags
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
| `repository_id` | integer | yes | The ID of registry repository. |
| `name_regex` | string | yes | The regex of the name to delete. To delete all tags specify `.*`. |
| `keep_n` | integer | no | The amount of latest tags of given name to keep. |
| `older_than` | string | no | Tags to delete that are older than the given time, written in human readable form `1h`, `1d`, `1month`. |

This API call performs the following operations:

1. It orders all tags by creation date. The creation date is the time of the
   manifest creation, not the time of tag push.
1. It removes only the tags matching the given `name_regex`.
1. It never removes the tag named `latest`.
1. It keeps N latest matching tags (if `keep_n` is specified).
1. It only removes tags that are older than X amount of time (if `older_than` is specified).
1. It schedules the asynchronous job to be executed in the background.

These operations are executed asynchronously and it might
take time to get executed. You can run this at most
once an hour for a given container repository.
This action does not delete blobs. In order to delete them and recycle disk space,
[run the garbage collection](https://docs.gitlab.com/omnibus/maintenance/README.html#removing-unused-layers-not-referenced-by-manifests).

NOTE: **Note:**
Due to a [Docker Distribution deficiency](https://gitlab.com/gitlab-org/gitlab-ce/issues/21405),
it doesn't remove tags whose manifest is shared by multiple tags.

Examples:

1. Remove tag names that are matching the regex (Git SHA), keep always at least 5,
   and remove ones that are older than 2 days:

   ```bash
   curl --request DELETE --data 'name_regex=[0-9a-z]{40}' --data 'keep_n=5' --data 'older_than=2d' --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
   ```

1. Remove all tags, but keep always the latest 5:

   ```bash
   curl --request DELETE --data 'name_regex=.*' --data 'keep_n=5' --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
   ```

1. Remove all tags that are older than 1 month:

   ```bash
   curl --request DELETE --data 'name_regex=.*' --data 'older_than=1month' --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
   ```

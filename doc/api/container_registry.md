---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Container Registry API

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/55978) in GitLab 11.8.
> - The use of `CI_JOB_TOKEN` scoped to the current project was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49750) in GitLab 13.12.

This is the API documentation of the [GitLab Container Registry](../user/packages/container_registry/index.md).

When the `ci_job_token_scope` feature flag is enabled (it is **disabled by default**), you can use the below endpoints
from a CI/CD job, by passing the `$CI_JOB_TOKEN` variable as the `JOB-TOKEN` header.
The job token will only have access to its own project.

[GitLab administrators with access to the GitLab Rails console](../administration/feature_flags.md)
can opt to enable it.

To enable it:

```ruby
Feature.enable(:ci_job_token_scope)
```

To disable it:

```ruby
Feature.disable(:ci_job_token_scope)
```

## List registry repositories

### Within a project

Get a list of registry repositories in a project.

```plaintext
GET /projects/:id/registry/repositories
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) accessible by the authenticated user. |
| `tags`      | boolean | no | If the parameter is included as true, each repository includes an array of `"tags"` in the response. |
| `tags_count` | boolean | no | If the parameter is included as true, each repository includes `"tags_count"` in the response ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/32141) in GitLab 13.1). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "",
    "path": "group/project",
    "project_id": 9,
    "location": "gitlab.example.com:5000/group/project",
    "created_at": "2019-01-10T13:38:57.391Z",
    "cleanup_policy_started_at": "2020-01-10T15:40:57.391Z"
  },
  {
    "id": 2,
    "name": "releases",
    "path": "group/project/releases",
    "project_id": 9,
    "location": "gitlab.example.com:5000/group/project/releases",
    "created_at": "2019-01-10T13:39:08.229Z",
    "cleanup_policy_started_at": "2020-08-17T03:12:35.489Z"
  }
]
```

### Within a group

Get a list of registry repositories in a group.

```plaintext
GET /groups/:id/registry/repositories
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) accessible by the authenticated user. |
| `tags`      | boolean | no | If the parameter is included as true, each repository includes an array of `"tags"` in the response. |
| `tags_count` | boolean | no | If the parameter is included as true, each repository includes `"tags_count"` in the response ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/32141) in GitLab 13.1). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/2/registry/repositories?tags=1&tags_count=true"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "",
    "path": "group/project",
    "project_id": 9,
    "location": "gitlab.example.com:5000/group/project",
    "created_at": "2019-01-10T13:38:57.391Z",
    "cleanup_policy_started_at": "2020-08-17T03:12:35.489Z",
    "tags_count": 1,
    "tags": [
      {
        "name": "0.0.1",
        "path": "group/project:0.0.1",
        "location": "gitlab.example.com:5000/group/project:0.0.1"
      }
    ]
  },
  {
    "id": 2,
    "name": "",
    "path": "group/other_project",
    "project_id": 11,
    "location": "gitlab.example.com:5000/group/other_project",
    "created_at": "2019-01-10T13:39:08.229Z",
    "cleanup_policy_started_at": "2020-01-10T15:40:57.391Z",
    "tags_count": 3,
    "tags": [
      {
        "name": "0.0.1",
        "path": "group/other_project:0.0.1",
        "location": "gitlab.example.com:5000/group/other_project:0.0.1"
      },
      {
        "name": "0.0.2",
        "path": "group/other_project:0.0.2",
        "location": "gitlab.example.com:5000/group/other_project:0.0.2"
      },
      {
        "name": "latest",
        "path": "group/other_project:latest",
        "location": "gitlab.example.com:5000/group/other_project:latest"
      }
    ]
  }
]
```

## Get details of a single repository

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/209916) in GitLab 13.6.

Get details of a registry repository.

```plaintext
GET /registry/repositories/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID of the registry repository accessible by the authenticated user. |
| `tags`      | boolean | no | If the parameter is included as `true`, the response includes an array of `"tags"`. |
| `tags_count` | boolean | no | If the parameter is included as `true`, the response includes `"tags_count"`. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/registry/repositories/2?tags=true&tags_count=true"
```

Example response:

```json
{
  "id": 2,
  "name": "",
  "path": "group/project",
  "project_id": 9,
  "location": "gitlab.example.com:5000/group/project",
  "created_at": "2019-01-10T13:38:57.391Z",
  "cleanup_policy_started_at": "2020-08-17T03:12:35.489Z",
  "tags_count": 1,
  "tags": [
    {
      "name": "0.0.1",
      "path": "group/project:0.0.1",
      "location": "gitlab.example.com:5000/group/project:0.0.1"
    }
  ]
}
```

## Delete registry repository

Delete a repository in registry.

This operation is executed asynchronously and might take some time to get executed.

```plaintext
DELETE /projects/:id/registry/repositories/:repository_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `repository_id` | integer | yes | The ID of registry repository. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2"
```

## List registry repository tags

### Within a project

Get a list of tags for given registry repository.

```plaintext
GET /projects/:id/registry/repositories/:repository_id/tags
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) accessible by the authenticated user. |
| `repository_id` | integer | yes | The ID of registry repository. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
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

## Get details of a registry repository tag

Get details of a registry repository tag.

```plaintext
GET /projects/:id/registry/repositories/:repository_id/tags/:tag_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) accessible by the authenticated user. |
| `repository_id` | integer | yes | The ID of registry repository. |
| `tag_name` | string | yes | The name of tag. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags/v10.0.0"
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

## Delete a registry repository tag

Delete a registry repository tag.

```plaintext
DELETE /projects/:id/registry/repositories/:repository_id/tags/:tag_name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `repository_id` | integer | yes | The ID of registry repository. |
| `tag_name` | string | yes | The name of tag. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags/v10.0.0"
```

This action doesn't delete blobs. To delete them and recycle disk space,
[run the garbage collection](https://docs.gitlab.com/omnibus/maintenance/README.html#removing-unused-layers-not-referenced-by-manifests).

## Delete registry repository tags in bulk

Delete registry repository tags in bulk based on given criteria.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Use the Container Registry API to delete all tags except *](https://youtu.be/Hi19bKe_xsg).

```plaintext
DELETE /projects/:id/registry/repositories/:repository_id/tags
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `repository_id` | integer | yes | The ID of registry repository. |
| `name_regex` | string | no | The [re2](https://github.com/google/re2/wiki/Syntax) regex of the name to delete. To delete all tags specify `.*`. **Note:** `name_regex` is deprecated in favor of `name_regex_delete`. This field is validated. |
| `name_regex_delete` | string | yes | The [re2](https://github.com/google/re2/wiki/Syntax) regex of the name to delete. To delete all tags specify `.*`. This field is validated. |
| `name_regex_keep` | string | no | The [re2](https://github.com/google/re2/wiki/Syntax) regex of the name to keep. This value overrides any matches from `name_regex_delete`. This field is validated. Note: setting to `.*` results in a no-op. |
| `keep_n` | integer | no | The amount of latest tags of given name to keep. |
| `older_than` | string | no | Tags to delete that are older than the given time, written in human readable form `1h`, `1d`, `1month`. |

This API call performs the following operations:

- It orders all tags by creation date. The creation date is the time of the
  manifest creation, not the time of tag push.
- It removes only the tags matching the given `name_regex_delete` (or deprecated
  `name_regex`), keeping any that match `name_regex_keep`.
- It never removes the tag named `latest`.
- It keeps N latest matching tags (if `keep_n` is specified).
- It only removes tags that are older than X amount of time (if `older_than` is
  specified).
- It schedules the asynchronous job to be executed in the background.

These operations are executed asynchronously and can take time to get executed.
You can run this at most once an hour for a given container repository. This
action doesn't delete blobs. To delete them and recycle disk space,
[run the garbage collection](https://docs.gitlab.com/omnibus/maintenance/README.html#removing-unused-layers-not-referenced-by-manifests).

WARNING:
The number of tags deleted by this API is limited on GitLab.com
because of the scale of the Container Registry there.
If your Container Registry has a large number of tags to delete,
only some of them will be deleted, and you might need to call this API multiple times.
To schedule tags for automatic deletion, use a [cleanup policy](../user/packages/container_registry/index.md#cleanup-policy) instead.

NOTE:
In GitLab 12.4 and later, individual tags are deleted.
For more details, see the [discussion](https://gitlab.com/gitlab-org/gitlab/-/issues/15737).

Examples:

1. Remove tag names that are matching the regex (Git SHA), keep always at least 5,
   and remove ones that are older than 2 days:

   ```shell
   curl --request DELETE --data 'name_regex_delete=[0-9a-z]{40}' --data 'keep_n=5' --data 'older_than=2d' \
        --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
   ```

1. Remove all tags, but keep always the latest 5:

   ```shell
   curl --request DELETE --data 'name_regex_delete=.*' --data 'keep_n=5' \
        --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
   ```

1. Remove all tags, but keep always tags beginning with `stable`:

   ```shell
   curl --request DELETE --data 'name_regex_delete=.*' --data 'name_regex_keep=stable.*' \
        --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
   ```

1. Remove all tags that are older than 1 month:

   ```shell
   curl --request DELETE --data 'name_regex_delete=.*' --data 'older_than=1month' \
        --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
   ```

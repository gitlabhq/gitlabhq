---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Container registry API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use these API endpoints to work with the [GitLab container registry](../user/packages/container_registry/_index.md).

You can authenticate with these endpoints from a CI/CD job by passing the [`$CI_JOB_TOKEN`](../ci/jobs/ci_job_token.md)
variable as the `JOB-TOKEN` header. The job token only has access to the container registry
of the project that created the pipeline.

## Change the visibility of the container registry

This controls who can view the container registry.

```plaintext
PUT /projects/:id/
```

| Attribute                         | Type           | Required | Description |
|-----------------------------------|----------------|----------|-------------|
| `id`                              | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) accessible by the authenticated user. |
| `container_registry_access_level` | string         | no       | The desired visibility of the container registry. One of `enabled` (default), `private`, or `disabled`. |

Descriptions of the possible values for `container_registry_access_level`:

- **enabled** (Default): The container registry is visible to everyone with access to the project.
  If the project is public, the container registry is also public. If the project is internal or
  private, the container registry is also internal or private.
- **private**: The container registry is visible only to project members with Reporter role or
  higher. This behavior is similar to that of a private project with container registry visibility set
  to **enabled**.
- **disabled**: The container registry is disabled.

See the [container registry visibility permissions](../user/packages/container_registry/_index.md#container-registry-visibility-permissions)
for more details about the permissions that this setting grants to users.

```shell
curl --request PUT "https://gitlab.example.com/api/v4/projects/5/" \
     --header 'PRIVATE-TOKEN: <your_access_token>' \
     --header 'Accept: application/json' \
     --header 'Content-Type: application/json' \
     --data-raw '{
         "container_registry_access_level": "private"
     }'
```

Example response:

```json
{
  "id": 5,
  "name": "Project 5",
  "container_registry_access_level": "private",
  ...
}
```

## Container registry pagination

By default, `GET` requests return 20 results at a time because the API results
are [paginated](rest/_index.md#pagination).

## List registry repositories

### Within a project

Get a list of registry repositories in a project.

```plaintext
GET /projects/:id/registry/repositories
```

| Attribute    | Type           | Required | Description |
|--------------|----------------|----------|-------------|
| `id`         | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) accessible by the authenticated user. |
| `tags`       | boolean        | no       | If the parameter is included as true, each repository includes an array of `"tags"` in the response. |
| `tags_count` | boolean        | no       | If the parameter is included as true, each repository includes `"tags_count"` in the response . |

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
    "cleanup_policy_started_at": "2020-01-10T15:40:57.391Z",
    "status": null
  },
  {
    "id": 2,
    "name": "releases",
    "path": "group/project/releases",
    "project_id": 9,
    "location": "gitlab.example.com:5000/group/project/releases",
    "created_at": "2019-01-10T13:39:08.229Z",
    "cleanup_policy_started_at": "2020-08-17T03:12:35.489Z",
    "status": "delete_ongoing"
  }
]
```

### Within a group

> - [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/336912) the `tags` and `tag_count` attributes in GitLab 15.0.

Get a list of registry repositories in a group.

```plaintext
GET /groups/:id/registry/repositories
```

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) accessible by the authenticated user. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/2/registry/repositories"
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
  },
  {
    "id": 2,
    "name": "",
    "path": "group/other_project",
    "project_id": 11,
    "location": "gitlab.example.com:5000/group/other_project",
    "created_at": "2019-01-10T13:39:08.229Z",
    "cleanup_policy_started_at": "2020-01-10T15:40:57.391Z",
  }
]
```

## Get details of a single repository

Get details of a registry repository.

```plaintext
GET /registry/repositories/:id
```

| Attribute    | Type           | Required | Description |
|--------------|----------------|----------|-------------|
| `id`         | integer/string | yes      | The ID of the registry repository accessible by the authenticated user. |
| `tags`       | boolean        | no       | If the parameter is included as `true`, the response includes an array of `"tags"`. |
| `tags_count` | boolean        | no       | If the parameter is included as `true`, the response includes `"tags_count"`. |
| `size`       | boolean        | no       | If the parameter is included as `true`, the response includes `"size"`. This is the deduplicated size of all images within the repository. Deduplication eliminates extra copies of identical data. For example, if you upload the same image twice, the container registry stores only one copy. This field is only available on GitLab.com for repositories created after `2021-11-04`. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/registry/repositories/2?tags=true&tags_count=true&size=true"
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
  ],
  "size": 2818413,
  "status": "delete_scheduled"
}
```

## Delete registry repository

Delete a repository in registry.

This operation is executed asynchronously and might take some time to get executed.

```plaintext
DELETE /projects/:id/registry/repositories/:repository_id
```

| Attribute       | Type           | Required | Description |
|-----------------|----------------|----------|-------------|
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `repository_id` | integer        | yes      | The ID of registry repository. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2"
```

## List registry repository tags

### Within a project

> - Keyset pagination [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/432470) in GitLab 16.10 for GitLab.com only.

Get a list of tags for given registry repository.

NOTE:
Offset pagination is deprecated and keyset pagination is now the preferred pagination method.

```plaintext
GET /projects/:id/registry/repositories/:repository_id/tags
```

| Attribute       | Type           | Required | Description |
|-----------------|----------------|----------|-------------|
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) accessible by the authenticated user. |
| `repository_id` | integer        | yes      | The ID of registry repository. |

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

| Attribute       | Type           | Required | Description |
|-----------------|----------------|----------|-------------|
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) accessible by the authenticated user. |
| `repository_id` | integer        | yes      | The ID of registry repository. |
| `tag_name`      | string         | yes      | The name of tag. |

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

| Attribute       | Type           | Required | Description |
|-----------------|----------------|----------|-------------|
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `repository_id` | integer        | yes      | The ID of registry repository. |
| `tag_name`      | string         | yes      | The name of tag. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags/v10.0.0"
```

This action doesn't delete blobs. To delete them and recycle disk space,
[run the garbage collection](../administration/packages/container_registry.md#container-registry-garbage-collection).

## Delete registry repository tags in bulk

Delete registry repository tags in bulk based on given criteria.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Use the container registry API to delete all tags except *](https://youtu.be/Hi19bKe_xsg).

```plaintext
DELETE /projects/:id/registry/repositories/:repository_id/tags
```

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `repository_id`     | integer        | yes      | The ID of registry repository. |
| `name_regex`        | string         | no       | The [re2](https://github.com/google/re2/wiki/Syntax) regex of the name to delete. To delete all tags specify `.*`. **Note:** `name_regex` is deprecated in favor of `name_regex_delete`. This field is validated. |
| `name_regex_delete` | string         | yes      | The [re2](https://github.com/google/re2/wiki/Syntax) regex of the name to delete. To delete all tags specify `.*`. This field is validated. |
| `name_regex_keep`   | string         | no       | The [re2](https://github.com/google/re2/wiki/Syntax) regex of the name to keep. This value overrides any matches from `name_regex_delete`. This field is validated. Note: setting to `.*` results in a no-op. |
| `keep_n`            | integer        | no       | The amount of latest tags of given name to keep. |
| `older_than`        | string         | no       | Tags to delete that are older than the given time, written in human readable form `1h`, `1d`, `1month`. |

This API returns [HTTP response status code 202](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/202)
if successful, and performs the following operations:

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
[run the garbage collection](../administration/packages/container_registry.md#container-registry-garbage-collection).

WARNING:
The number of tags deleted by this API is limited on GitLab.com
because of the scale of the container registry there.
If your container registry has a large number of tags to delete,
only some of them are deleted, and you might need to call this API multiple times.
To schedule tags for automatic deletion, use a [cleanup policy](../user/packages/container_registry/reduce_container_registry_storage.md#cleanup-policy) instead.

Examples:

- Remove tag names that are matching the regex (Git SHA), keep always at least 5,
  and remove ones that are older than 2 days:

  ```shell
  curl --request DELETE --data 'name_regex_delete=[0-9a-z]{40}' --data 'keep_n=5' --data 'older_than=2d' \
       --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
  ```

- Remove all tags, but keep always the latest 5:

  ```shell
  curl --request DELETE --data 'name_regex_delete=.*' --data 'keep_n=5' \
       --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
  ```

- Remove all tags, but keep always tags beginning with `stable`:

  ```shell
  curl --request DELETE --data 'name_regex_delete=.*' --data 'name_regex_keep=stable.*' \
       --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
  ```

- Remove all tags that are older than 1 month:

  ```shell
  curl --request DELETE --data 'name_regex_delete=.*' --data 'older_than=1month' \
       --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
  ```

### Use cURL with a regular expression that contains `+`

When using cURL, the `+` character in regular expressions must be
[URL-encoded](https://curl.se/docs/manpage.html#--data-urlencode),
to be processed correctly by the GitLab Rails backend. For example:

```shell
curl --request DELETE --data-urlencode 'name_regex_delete=dev-.+' \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
```

## Instance-wide endpoints

Beside the group- and project-specific GitLab APIs explained above,
the container registry has its own endpoints.
To query those, follow the Registry's built-in mechanism to obtain and use an
[authentication token](https://distribution.github.io/distribution/spec/auth/token/).

NOTE:
These are different from project or personal access tokens in the GitLab application.

### Obtain token from GitLab

```plaintext
GET ${CI_SERVER_URL}/jwt/auth?service=container_registry&scope=*
```

You must specify the correct [scopes and actions](https://distribution.github.io/distribution/spec/auth/scope/) to retrieve a valid token:

```shell
$ SCOPE="repository:${CI_REGISTRY_IMAGE}:delete" #or push,pull

$ curl  --request GET --user "${CI_REGISTRY_USER}:${CI_REGISTRY_PASSWORD}" \
        "https://gitlab.example.com/jwt/auth?service=container_registry&scope=${SCOPE}"
{"token":" ... "}
```

### Delete image tags by reference

> - Endpoint `v2/<name>/manifests/<tag>` [introduced](https://gitlab.com/gitlab-org/container-registry/-/issues/1091) and endpoint `v2/<name>/tags/reference/<tag>` [deprecated](https://gitlab.com/gitlab-org/container-registry/-/issues/1094) in GitLab 16.4.

```plaintext
DELETE http(s)://${CI_REGISTRY}/v2/${CI_REGISTRY_IMAGE}/tags/reference/${CI_COMMIT_SHORT_SHA}
```

You can use the token retrieved with the predefined `CI_REGISTRY_USER` and `CI_REGISTRY_PASSWORD` variables to delete container image tags by reference on your GitLab instance.
The `tag_delete` [Container-Registry-Feature](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/docker/v2/api.md#delete-tag) must be enabled.

```shell
$ curl  --request DELETE --header "Authorization: Bearer <token_from_above>" \
        --header "Accept: application/vnd.docker.distribution.manifest.v2+json" \
        "https://gitlab.example.com:5050/v2/${CI_REGISTRY_IMAGE}/manifests/${CI_COMMIT_SHORT_SHA}"
```

### Listing all container repositories

```plaintext
GET http(s)://${CI_REGISTRY}/v2/_catalog
```

To list all container repositories on your GitLab instance, administrator credentials are required:

```shell
$ SCOPE="registry:catalog:*"

$ curl  --request GET --user "<admin-username>:<admin-password>" \
        "https://gitlab.example.com/jwt/auth?service=container_registry&scope=${SCOPE}"
{"token":" ... "}

$ curl --header "Authorization: Bearer <token_from_above>" https://gitlab.example.com:5050/v2/_catalog
```

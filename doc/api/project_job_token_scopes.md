---
stage: Software Supply Chain Security
group: Pipeline Security
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Project CI/CD job token scope API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can read more about the [CI/CD job token](../ci/jobs/ci_job_token.md).

NOTE:
All requests to the CI/CD job token scope API endpoint must be [authenticated](rest/authentication.md).
The authenticated user must have at least the Maintainer role for the project.

## Get a project's CI/CD job token access settings

Fetch the [CI/CD job token access settings](../ci/jobs/ci_job_token.md#control-job-token-access-to-your-project) (job token scope) of a project.

```plaintext
GET /projects/:id/job_token_scope
```

Supported attributes:

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute          | Type    | Description |
|--------------------|---------|-------------|
| `inbound_enabled`  | boolean | Indicates if the [**Limit access _to_ this project** setting](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) is enabled. If disabled, then [all projects have access](../ci/jobs/ci_job_token.md#allow-any-project-to-access-your-project). |
| `outbound_enabled` | boolean | Indicates if the CI/CD job token generated in this project has access to other projects. [Deprecated and planned for removal in GitLab 18.0](../update/deprecations.md#cicd-job-token---limit-access-from-your-project-setting-removal). |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/job_token_scope"
```

Example response:

```json
{
  "inbound_enabled": true,
  "outbound_enabled": false
}
```

## Patch a project's CI/CD job token access settings

> - **Allow access to this project with a CI_JOB_TOKEN** setting [renamed to **Limit access _to_ this project**](https://gitlab.com/gitlab-org/gitlab/-/issues/411406) in GitLab 16.3.

Patch the [**Limit access _to_ this project** setting](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) (job token scope) of a project.

```plaintext
PATCH /projects/:id/job_token_scope
```

Supported attributes:

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `enabled` | boolean        | Yes      | Indicates if the [**Limit access _to_ this project** setting](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) should be enabled. |

If successful, returns [`204`](rest/troubleshooting.md#status-codes) and no response body.

Example request:

```shell
curl --request PATCH \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json' \
  --data '{ "enabled": false }'
```

## Get a project's CI/CD job token inbound allowlist

Fetch the [CI/CD job token inbound allowlist](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) (job token scope) of a project.

```plaintext
GET /projects/:id/job_token_scope/allowlist
```

Supported attributes:

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

This endpoint supports [offset-based pagination](rest/_index.md#offset-based-pagination).

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and a list of project with limited fields for each project.

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/job_token_scope/allowlist"
```

Example response:

```json
[
  {
    "id": 4,
    "description": null,
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "created_at": "2013-09-30T13:46:02Z",
    "default_branch": "main",
    "tag_list": [
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "ssh_url_to_repo": "git@gitlab.example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "https://gitlab.example.com/diaspora/diaspora-client.git",
    "web_url": "https://gitlab.example.com/diaspora/diaspora-client",
    "avatar_url": "https://gitlab.example.com/uploads/project/avatar/4/uploads/avatar.png",
    "star_count": 0,
    "last_activity_at": "2013-09-30T13:46:02Z",
    "namespace": {
      "id": 2,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora",
      "parent_id": null,
      "avatar_url": null,
      "web_url": "https://gitlab.example.com/diaspora"
    }
  },
  {
    ...
  }
```

## Add a project to a CI/CD job token inbound allowlist

Add a project to the [CI/CD job token inbound allowlist](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) of a project.

```plaintext
POST /projects/:id/job_token_scope/allowlist
```

Supported attributes:

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `target_project_id` | integer        | Yes      | The ID of the project added to the CI/CD job token inbound allowlist. |

If successful, returns [`201`](rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute           | Type    | Description |
|---------------------|---------|-------------|
| `source_project_id` | integer | ID of the project containing the CI/CD job token inbound allowlist to update. |
| `target_project_id` | integer | ID of the project that is added to the source project's inbound allowlist. |

Example request:

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/allowlist" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json' \
  --data '{ "target_project_id": 2 }'
```

Example response:

```json
{
  "source_project_id": 1,
  "target_project_id": 2
}
```

## Remove a project from a CI/CD job token inbound allowlist

Remove a project from the [CI/CD job token inbound allowlist](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) of a project.

```plaintext
DELETE /projects/:id/job_token_scope/allowlist/:target_project_id
```

Supported attributes:

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `target_project_id` | integer        | Yes      | The ID of the project that is removed from the CI/CD job token inbound allowlist. |

If successful, returns [`204`](rest/troubleshooting.md#status-codes) and no response body.

Example request:

```shell
curl --request DELETE \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/allowlist/2" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json'
```

## Get a project's CI/CD job token allowlist of groups

Fetch the CI/CD job token allowlist of groups (job token scope) of a project.

```plaintext
GET /projects/:id/job_token_scope/groups_allowlist
```

Supported attributes:

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

This endpoint supports [offset-based pagination](rest/_index.md#offset-based-pagination).

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and a list of groups with limited fields for each project.

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/job_token_scope/groups_allowlist"
```

Example response:

```json
[
  {
    "id": 4,
    "web_url": "https://gitlab.example.com/groups/diaspora/diaspora-group",
    "name": "namegroup"
  },
  {
    ...
  }
]
```

## Add a group to a CI/CD job token allowlist

Add a group to the CI/CD job token allowlist of a project.

```plaintext
POST /projects/:id/job_token_scope/groups_allowlist
```

Supported attributes:

| Attribute         | Type           | Required | Description |
|-------------------|----------------|----------|-------------|
| `id`              | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `target_group_id` | integer        | Yes      | The ID of the group added to the CI/CD job token groups allowlist. |

If successful, returns [`201`](rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute           | Type    | Description |
|---------------------|---------|-------------|
| `source_project_id` | integer | ID of the project containing the CI/CD job token inbound allowlist to update. |
| `target_group_id`   | integer | ID of the group that is added to the source project's groups allowlist. |

Example request:

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/groups_allowlist" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json' \
  --data '{ "target_group_id": 2 }'
```

Example response:

```json
{
  "source_project_id": 1,
  "target_group_id": 2
}
```

## Remove a group from a CI/CD job token allowlist

Remove a group from the CI/CD job token allowlist of a project.

```plaintext
DELETE /projects/:id/job_token_scope/groups_allowlist/:target_group_id
```

Supported attributes:

| Attribute         | Type           | Required | Description |
|-------------------|----------------|----------|-------------|
| `id`              | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `target_group_id` | integer        | Yes      | The ID of the group that is removed from the CI/CD job token groups allowlist. |

If successful, returns [`204`](rest/troubleshooting.md#status-codes) and no response body.

Example request:

```shell
curl --request DELETE \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/groups_allowlist/2" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json'
```

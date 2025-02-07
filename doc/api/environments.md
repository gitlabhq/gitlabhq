---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Environments API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> Parameter `auto_stop_setting` [added](https://gitlab.com/gitlab-org/gitlab/-/issues/428625) in GitLab 17.8.
> Support for [GitLab CI/CD job token](../ci/jobs/ci_job_token.md) authentication [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/414549) in GitLab 16.2.

## List environments

Get all environments for a given project.

```plaintext
GET /projects/:id/environments
```

| Attribute | Type           | Required | Description                                                                                                                                                   |
|-----------|----------------|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | The ID or [URL-encoded](rest/_index.md#namespaced-paths) path of the project.                                                                          |
| `name`    | string         | no       | Return the environment with this name. Mutually exclusive with `search`.                                                                                      |
| `search`  | string         | no       | Return list of environments matching the search criteria. Mutually exclusive with `name`. Must be at least 3 characters long.                                 |
| `states`  | string         | no       | List all environments that match a specific state. Accepted values: `available`, `stopping`, or `stopped`. If no state value given, returns all environments. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments?name=review%2Ffix-foo"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "review/fix-foo",
    "slug": "review-fix-foo-dfjre3",
    "description": "This is review environment",
    "external_url": "https://review-fix-foo-dfjre3.gitlab.example.com",
    "state": "available",
    "tier": "development",
    "created_at": "2019-05-25T18:55:13.252Z",
    "updated_at": "2019-05-27T18:55:13.252Z",
    "enable_advanced_logs_querying": false,
    "logs_api_path": "/project/-/logs/k8s.json?environment_name=review%2Ffix-foo",
    "auto_stop_at": "2019-06-03T18:55:13.252Z",
    "kubernetes_namespace": "flux-system",
    "flux_resource_path": "HelmRelease/flux-system",
    "auto_stop_setting": "always"
  }
]
```

## Get a specific environment

```plaintext
GET /projects/:id/environments/:environment_id
```

| Attribute        | Type           | Required | Description                                                                          |
|------------------|----------------|----------|--------------------------------------------------------------------------------------|
| `id`             | integer/string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the project. |
| `environment_id` | integer        | yes      | The ID of the environment.                                                           |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/1"
```

Example of response

```json
{
  "id": 1,
  "name": "review/fix-foo",
  "slug": "review-fix-foo-dfjre3",
  "description": "This is review environment",
  "external_url": "https://review-fix-foo-dfjre3.gitlab.example.com",
  "state": "available",
  "tier": "development",
  "created_at": "2019-05-25T18:55:13.252Z",
  "updated_at": "2019-05-27T18:55:13.252Z",
  "enable_advanced_logs_querying": false,
  "logs_api_path": "/project/-/logs/k8s.json?environment_name=review%2Ffix-foo",
  "auto_stop_at": "2019-06-03T18:55:13.252Z",
  "last_deployment": {
    "id": 100,
    "iid": 34,
    "ref": "fdroid",
    "sha": "416d8ea11849050d3d1f5104cf8cf51053e790ab",
    "created_at": "2019-03-25T18:55:13.252Z",
    "status": "success",
    "user": {
      "id": 1,
      "name": "Administrator",
      "state": "active",
      "username": "root",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "deployable": {
      "id": 710,
      "status": "success",
      "stage": "deploy",
      "name": "staging",
      "ref": "fdroid",
      "tag": false,
      "coverage": null,
      "created_at": "2019-03-25T18:55:13.215Z",
      "started_at": "2019-03-25T12:54:50.082Z",
      "finished_at": "2019-03-25T18:55:13.216Z",
      "duration": 21623.13423,
      "project": {
        "ci_job_token_scope_enabled": false
      },
      "user": {
        "id": 1,
        "name": "Administrator",
        "username": "root",
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "http://gitlab.dev/root",
        "created_at": "2015-12-21T13:14:24.077Z",
        "bio": null,
        "location": null,
        "public_email": "",
        "skype": "",
        "linkedin": "",
        "twitter": "",
        "website_url": "",
        "organization": null
      },
      "commit": {
        "id": "416d8ea11849050d3d1f5104cf8cf51053e790ab",
        "short_id": "416d8ea1",
        "created_at": "2016-01-02T15:39:18.000Z",
        "parent_ids": [
          "e9a4449c95c64358840902508fc827f1a2eab7df"
        ],
        "title": "Removed fabric to fix #40",
        "message": "Removed fabric to fix #40\n",
        "author_name": "Administrator",
        "author_email": "admin@example.com",
        "authored_date": "2016-01-02T15:39:18.000Z",
        "committer_name": "Administrator",
        "committer_email": "admin@example.com",
        "committed_date": "2016-01-02T15:39:18.000Z"
      },
      "pipeline": {
        "id": 34,
        "sha": "416d8ea11849050d3d1f5104cf8cf51053e790ab",
        "ref": "fdroid",
        "status": "success",
        "web_url": "http://localhost:3000/Commit451/lab-coat/pipelines/34"
      },
      "web_url": "http://localhost:3000/Commit451/lab-coat/-/jobs/710",
      "artifacts": [
        {
          "file_type": "trace",
          "size": 1305,
          "filename": "job.log",
          "file_format": null
        }
      ],
      "runner": null,
      "artifacts_expire_at": null
    }
  },
  "cluster_agent": {
    "id": 1,
    "name": "agent-1",
    "config_project": {
      "id": 20,
      "description": "",
      "name": "test",
      "name_with_namespace": "Administrator / test",
      "path": "test",
      "path_with_namespace": "root/test",
      "created_at": "2022-03-20T20:42:40.221Z"
    },
    "created_at": "2022-04-20T20:42:40.221Z",
    "created_by_user_id": 42
  },
  "kubernetes_namespace": "flux-system",
  "flux_resource_path": "HelmRelease/flux-system",
  "auto_stop_setting": "always"
}
```

## Create a new environment

Creates a new environment with the given name and `external_url`.

It returns `201` if the environment was successfully created, `400` for wrong parameters.

```plaintext
POST /projects/:id/environments
```

| Attribute              | Type           | Required | Description                                                                                                         |
|------------------------|----------------|----------|---------------------------------------------------------------------------------------------------------------------|
| `id`                   | integer/string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the project.                                |
| `name`                 | string         | yes      | The name of the environment.                                                                                        |
| `description`          | string         | no       | The description of the environment.                                                                                        |
| `external_url`         | string         | no       | Place to link to for this environment.                                                                              |
| `tier`                 | string         | no       | The tier of the new environment. Allowed values are `production`, `staging`, `testing`, `development`, and `other`. |
| `cluster_agent_id`     | integer        | no       | The cluster agent to associate with this environment.                                                               |
| `kubernetes_namespace` | string         | no       | The Kubernetes namespace to associate with this environment.                                                        |
| `flux_resource_path`   | string         | no       | The Flux resource path to associate with this environment. This must be the full resource path. For example, `helm.toolkit.fluxcd.io/v2/namespaces/gitlab-agent/helmreleases/gitlab-agent`.  |
| `auto_stop_setting`    | string         | no       | The auto stop setting for the environment. Allowed values are `always` or `with_action`. |

```shell
curl --data "name=deploy&external_url=https://deploy.gitlab.example.com" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments"
```

Example response:

```json
{
  "id": 1,
  "name": "deploy",
  "slug": "deploy",
  "description": null,
  "external_url": "https://deploy.gitlab.example.com",
  "state": "available",
  "tier": "production",
  "created_at": "2019-05-25T18:55:13.252Z",
  "updated_at": "2019-05-27T18:55:13.252Z",
  "kubernetes_namespace": "flux-system",
  "flux_resource_path": "HelmRelease/flux-system",
  "auto_stop_setting": "always"
}
```

## Update an existing environment

> - Parameter `name` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/338897) in GitLab 16.0.

Updates an existing environment's name and/or `external_url`.

It returns `200` if the environment was successfully updated. In case of an error, a status code `400` is returned.

```plaintext
PUT /projects/:id/environments/:environments_id
```

| Attribute              | Type            | Required | Description                                                                                                         |
|------------------------|-----------------|----------|---------------------------------------------------------------------------------------------------------------------|
| `id`                   | integer/string  | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).                                |
| `environment_id`       | integer         | yes      | The ID of the environment.                                                                                          |
| `description`          | string          | no       | The description of the environment.                                                                                        |
| `external_url`         | string          | no       | The new `external_url`.                                                                                             |
| `tier`                 | string          | no       | The tier of the new environment. Allowed values are `production`, `staging`, `testing`, `development`, and `other`. |
| `cluster_agent_id`     | integer or null | no       | The cluster agent to associate with this environment or `null` to remove it.                                        |
| `kubernetes_namespace` | string or null  | no       | The Kubernetes namespace to associate with this environment or `null` to remove it.                                 |
| `flux_resource_path`   | string or null  | no       | The Flux resource path to associate with this environment or `null` to remove it.                                   |
| `auto_stop_setting`    | string or null  | no       | The auto stop setting for the environment. Allowed values are `always` or `with_action`. |

```shell
curl --request PUT \
  --data "external_url=https://staging.gitlab.example.com" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/1"
```

Example response:

```json
{
  "id": 1,
  "name": "staging",
  "slug": "staging",
  "description": null,
  "external_url": "https://staging.gitlab.example.com",
  "state": "available",
  "tier": "staging",
  "created_at": "2019-05-25T18:55:13.252Z",
  "updated_at": "2019-05-27T18:55:13.252Z",
  "kubernetes_namespace": "flux-system",
  "flux_resource_path": "HelmRelease/flux-system",
  "auto_stop_setting": "always"
}
```

## Delete an environment

It returns `204` if the environment was successfully deleted, and `404` if the environment does not exist. The environment must be stopped first, otherwise the request returns `403`.

```plaintext
DELETE /projects/:id/environments/:environment_id
```

| Attribute        | Type           | Required | Description                                                                          |
|------------------|----------------|----------|--------------------------------------------------------------------------------------|
| `id`             | integer/string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the project. |
| `environment_id` | integer        | yes      | The ID of the environment.                                                           |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/1"
```

## Delete multiple stopped review apps

It schedules for deletion multiple environments that have already been
[stopped](../ci/environments/_index.md#stopping-an-environment) and
are [in the review app folder](../ci/review_apps/_index.md).
The actual deletion is performed after 1 week from the time of execution.
By default, it only deletes environments 30 days or older. You can change this default using the `before` parameter.

```plaintext
DELETE /projects/:id/environments/review_apps
```

| Attribute | Type           | Required | Description                                                                                                                                            |
|-----------|----------------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the project.                                                                   |
| `before`  | datetime       | no       | The date before which environments can be deleted. Defaults to 30 days ago. Expected in ISO 8601 format (`YYYY-MM-DDTHH:MM:SSZ`).                      |
| `limit`   | integer        | no       | Maximum number of environments to delete. Defaults to 100.                                                                                             |
| `dry_run` | boolean        | no       | Defaults to `true` for safety reasons. It performs a dry run where no actual deletion is performed. Set to `false` to actually delete the environment. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/review_apps"
```

Example response:

```json
{
  "scheduled_entries": [
    {
      "id": 387,
      "name": "review/023f1bce01229c686a73",
      "slug": "review-023f1bce01-3uxznk",
      "external_url": null
    },
    {
      "id": 388,
      "name": "review/85d4c26a388348d3c4c0",
      "slug": "review-85d4c26a38-5giw1c",
      "external_url": null
    }
  ],
  "unprocessable_entries": []
}
```

## Stop an environment

It returns `200` if the environment was successfully stopped, and `404` if the environment does not exist.

```plaintext
POST /projects/:id/environments/:environment_id/stop
```

| Attribute        | Type           | Required | Description                                                                          |
|------------------|----------------|----------|--------------------------------------------------------------------------------------|
| `id`             | integer/string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the project. |
| `environment_id` | integer        | yes      | The ID of the environment.                                                           |
| `force`          | boolean        | no       | Force environment to stop without executing `on_stop` actions.                       |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/1/stop"
```

Example response:

```json
{
  "id": 1,
  "name": "deploy",
  "slug": "deploy",
  "external_url": "https://deploy.gitlab.example.com",
  "state": "stopped",
  "created_at": "2019-05-25T18:55:13.252Z",
  "updated_at": "2019-05-27T18:55:13.252Z",
  "kubernetes_namespace": "flux-system",
  "flux_resource_path": "HelmRelease/flux-system",
  "auto_stop_setting": "always"
}
```

## Stop stale environments

Issue stop request to all environments that were last modified or deployed to before a specified date. Excludes protected environments. Returns `200` if stop request was successful and `400` if the before date is invalid. For details of exactly when the environment is stopped, see [Stop an environment](../ci/environments/_index.md#stopping-an-environment).

```plaintext
POST /projects/:id/environments/stop_stale
```

| Attribute | Type           | Required | Description                                                                                                                                                                                    |
|-----------|----------------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the project.                                                                                                           |
| `before`  | date           | yes      | Stop environments that have been modified or deployed to before the specified date. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). Valid inputs are between 10 years ago and 1 week ago |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/stop_stale?before=10%2F10%2F2021"
```

Example response:

```json
{
  "message": "Successfully requested stop for all stale environments"
}
```

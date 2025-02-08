---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Pull mirroring API
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can manage project [pull mirroring](../user/project/repository/mirror/pull.md) by using the REST API.

## Get a project's pull mirror details

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/354506) in GitLab 15.6.
> - [Extended response](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/168377) to include mirror configuration information in GitLab 17.5. The following configuration settings are included: `enabled`, `mirror_trigger_builds`, `only_mirror_protected_branches`, `mirror_overwrites_diverged_branches`, and `mirror_branch_regex`.

Return the details of a project's [pull mirror](../user/project/repository/mirror/_index.md).

```plaintext
GET /projects/:id/mirror/pull
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute                             | Type            | Description                                                                 |
|---------------------------------------|-----------------|-----------------------------------------------------------------------------|
| `id`                                  | integer         | The unique identifier of the mirror configuration.                          |
| `last_error`                          | string or null  | The most recent error message, if any. `null` if no errors occurred.        |
| `last_successful_update_at`           | string          | Timestamp of the last successful mirror update.                             |
| `last_update_at`                      | string          | Timestamp of the most recent mirror update attempt.                         |
| `last_update_started_at`              | string          | Timestamp when the last mirror update process started.                      |
| `update_status`                       | string          | The status of the mirror update process.                                    |
| `url`                                 | string          | URL of the mirrored repository.                                             |
| `enabled`                             | boolean         | Indicates whether the mirror is active or inactive.                         |
| `mirror_trigger_builds`               | boolean         | Determines if builds should be triggered for mirror updates.                |
| `only_mirror_protected_branches`      | boolean or null | Specifies if only protected branches should be mirrored. `null` if not set. |
| `mirror_overwrites_diverged_branches` | boolean         | Indicates if diverged branches should be overwritten during mirroring.      |
| `mirror_branch_regex`                 | string or null  | Regex pattern for filtering which branches to mirror. `null` if not set.    |

Example response:

```json
{
  "id": 101486,
  "last_error": null,
  "last_successful_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_started_at": "2020-01-06T17:31:55.864Z",
  "update_status": "finished",
  "url": "https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git",
  "enabled": true,
  "mirror_trigger_builds": true,
  "only_mirror_protected_branches": null,
  "mirror_overwrites_diverged_branches": false,
  "mirror_branch_regex": null
}
```

## Configure pull mirroring for a project

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/494294) in GitLab 17.6.

Configure pull mirroring settings.

Supported attributes:

| Attribute | Type | Required | Description |
|:----------|:-----|:---------|:------------|
| `enabled` | boolean | No | Enables pull mirroring on project when set to `true`. |
| `url` | string | No | URL of remote repository being mirrored. |
| `auth_user` | string | No | Username used for authentication of a project to pull mirror. |
| `auth_password` | string | No | Password used for authentication of a project to pull mirror. |
| `mirror_trigger_builds` | boolean | No | Trigger pipelines for mirror updates when set to `true`. |
| `only_mirror_protected_branches` | boolean | No | Limits mirroring to only protected branches when set to `true`. |
| `mirror_overwrites_diverged_branches` | boolean | No | Overwrite diverged branches. |
| `mirror_branch_regex` | String | No | Contains a regular expression. Only branches with names matching the regex are mirrored. Requires `only_mirror_protected_branches` to be disabled. |

Example request to add pull mirroring:

```shell
curl --request PUT \
 --header "PRIVATE-TOKEN: <your_access_token>" \
 --header "Content-Type: application/json" \
 --data '{
  "enabled": true,
  "url": "https://gitlab.example.com/group/project.git",
  "auth_user": "user",
  "auth_password": "password"
 }' \
 --url "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```

Example request to remove pull mirroring:

```shell
curl --request PUT \
 --header "PRIVATE-TOKEN: <your_access_token>" \
 --url "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"  \
 --data "enabled=false"
```

## Configure pull mirroring for a project (deprecated)

> - Field `mirror_branch_regex` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/381667) in GitLab 15.8 [with a flag](../administration/feature_flags.md) named `mirror_only_branches_match_regex`. Disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/381667) in GitLab 16.0.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/410354) in GitLab 16.2. Feature flag `mirror_only_branches_match_regex` removed.
> - [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/494294) in GitLab 17.6.

WARNING:
This configuration option was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/494294) in GitLab 17.6
and is planned for removal in v5 of the API. Use the [new configuration and endpoint](project_pull_mirroring.md#configure-pull-mirroring-for-a-project) instead.
This change is a breaking change.

Configure pull mirroring while [creating a new project](projects.md#create-a-project) or
[updating an existing project](projects.md#edit-a-project) by using the API if the remote repository is accessible publicly or by
using `username:token` authentication.

If your HTTP repository is not publicly accessible, you can add the authentication information to the URL. For example,
`https://username:token@gitlab.company.com/group/project.git` where `token` is a
[personal access token](../user/profile/personal_access_tokens.md) with the `api` scope enabled.

Supported attributes:

| Attribute                        | Type    | Required | Description |
|:---------------------------------|:--------|:---------|:------------|
| `import_url`                     | string  | Yes      | URL of remote repository being mirrored (with `user:token` if needed). |
| `mirror`                         | boolean | Yes      | Enables pull mirroring on project when set to `true`. |
| `mirror_trigger_builds`          | boolean | No       | Trigger pipelines for mirror updates when set to `true`. |
| `only_mirror_protected_branches` | boolean | No       | Limits mirroring to only protected branches when set to `true`. |
| `mirror_branch_regex`            | String  | No       | Contains a regular expression. Only branches with names matching the regex are mirrored. Requires `only_mirror_protected_branches` to be disabled. |

Example creating a project with pull mirroring:

```shell
curl --request POST \
 --header "PRIVATE-TOKEN: <your_access_token>" \
 --header "Content-Type: application/json" \
 --data '{
  "name": "new_project",
  "namespace_id": "1",
  "mirror": true,
  "import_url": "https://username:token@gitlab.example.com/group/project.git"
 }' \
 --url "https://gitlab.example.com/api/v4/projects/"
```

Example adding pull mirroring:

```shell
curl --request PUT \
 --header "PRIVATE-TOKEN: <your_access_token>" \
 --url "https://gitlab.example.com/api/v4/projects/:id" \
 --data "mirror=true&import_url=https://username:token@gitlab.example.com/group/project.git"
```

Example removing pull mirroring:

```shell
curl --request PUT \
 --header "PRIVATE-TOKEN: <your_access_token>" \
 --url "https://gitlab.example.com/api/v4/projects/:id"  \
 --data "mirror=false"
```

## Start the pull mirroring process for a project

Start the pull mirroring process for a project.

```plaintext
POST /projects/:id/mirror/pull
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```

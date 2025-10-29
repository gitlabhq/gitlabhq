---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Pull mirroring API
description: Manage pull mirroring for projects. View mirror details, configure mirroring settings, and start mirror updates.
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to manage project [pull mirroring](../user/project/repository/mirror/pull.md).

## Get a project's pull mirror details

{{< history >}}

- [Extended response](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/168377) to include mirror configuration information in GitLab 17.5. The following configuration settings are included: `enabled`, `mirror_trigger_builds`, `only_mirror_protected_branches`, `mirror_overwrites_diverged_branches`, and `mirror_branch_regex`.

{{< /history >}}

Return the details of a project's pull mirror.

```plaintext
GET /projects/:id/mirror/pull
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute                             | Type            | Description |
|---------------------------------------|-----------------|-------------|
| `enabled`                             | boolean         | If `true`, the mirror is active. |
| `id`                                  | integer         | Unique identifier of the mirror configuration. |
| `last_error`                          | string or null  | Most recent error message, if any. `null` if no errors occurred. |
| `last_successful_update_at`           | string          | Timestamp of the last successful mirror update. |
| `last_update_at`                      | string          | Timestamp of the most recent mirror update attempt. |
| `last_update_started_at`              | string          | Timestamp when the last mirror update process started. |
| `mirror_branch_regex`                 | string or null  | Regex pattern for filtering which branches to mirror. `null` if not set. |
| `mirror_overwrites_diverged_branches` | boolean         | If `true`, overwrites diverged branches during mirroring. |
| `mirror_trigger_builds`               | boolean         | If `true`, triggers builds for mirror updates. |
| `only_mirror_protected_branches`      | boolean or null | If `true`, only protected branches are mirrored. If not set, the value is `null`. |
| `update_status`                       | string          | Status of the mirror update process. |
| `url`                                 | string          | URL of the mirrored repository. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```

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

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/494294) in GitLab 17.6.

{{< /history >}}

Configure pull mirroring settings for a project.

```plaintext
PUT /projects/:id/mirror/pull
```

Supported attributes:

| Attribute                             | Type              | Required | Description |
|:--------------------------------------|:------------------|:---------|:------------|
| `id`                                  | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `auth_password`                       | string            | No       | Password used for authentication of a project to pull mirror. |
| `auth_user`                           | string            | No       | Username used for authentication of a project to pull mirror. |
| `enabled`                             | boolean           | No       | If `true`, enables pull mirroring on project when set to `true`. |
| `mirror_branch_regex`                 | string            | No       | Contains a regular expression. Only branches with names matching the regex are mirrored. Requires `only_mirror_protected_branches` to be disabled. |
| `mirror_overwrites_diverged_branches` | boolean           | No       | If `true`, overwrites diverged branches. |
| `mirror_trigger_builds`               | boolean           | No       | If `true`, triggers pipelines for mirror updates. |
| `only_mirror_protected_branches`      | boolean           | No       | If `true`, limits mirroring to only protected branches. |
| `url`                                 | string            | No       | URL of remote repository being mirrored. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
updated pull mirror configuration.

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
  --data "enabled=false" \
  --url "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```

Example response:

```json
{
  "id": 101486,
  "last_error": null,
  "last_successful_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_started_at": "2020-01-06T17:31:55.864Z",
  "update_status": "finished",
  "url": "https://gitlab.example.com/group/project.git",
  "enabled": true,
  "mirror_trigger_builds": false,
  "only_mirror_protected_branches": null,
  "mirror_overwrites_diverged_branches": false,
  "mirror_branch_regex": null
}
```

## Configure pull mirroring for a project (deprecated)

{{< history >}}

- Feature flag `mirror_only_branches_match_regex` [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/381667) in GitLab 16.0.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/410354) in GitLab 16.2. Feature flag `mirror_only_branches_match_regex` removed.
- [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/494294) in GitLab 17.6.

{{< /history >}}

{{< alert type="warning" >}}

This configuration option was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/494294) in GitLab 17.6
and is planned for removal in v5 of the API. Use the [new configuration and endpoint](project_pull_mirroring.md#configure-pull-mirroring-for-a-project) instead.
This change is a breaking change.

{{< /alert >}}

If the remote repository is publicly accessible or uses `username:token` authentication, use the API
to configure pull mirroring when [creating](projects.md#create-a-project) or [updating](projects.md#edit-a-project)
a project.

If your HTTP repository is not publicly accessible, you can add the authentication information to the URL. For example,
`https://username:token@gitlab.company.com/group/project.git` where `token` is a
[personal access token](../user/profile/personal_access_tokens.md) with the `api` scope enabled.

Supported attributes:

| Attribute                        | Type    | Required | Description |
|:---------------------------------|:--------|:---------|:------------|
| `import_url`                     | string  | Yes      | URL of remote repository being mirrored (with `user:token` if needed). |
| `mirror`                         | boolean | Yes      | If `true`, enables pull mirroring. |
| `mirror_branch_regex`            | string  | No       | Contains a regular expression. Only branches with names matching the regex are mirrored. Requires `only_mirror_protected_branches` to be disabled. |
| `mirror_trigger_builds`          | boolean | No       | If `true`, triggers pipelines for mirror updates. |
| `only_mirror_protected_branches` | boolean | No       | If `true`, limits mirroring to only protected branches. |

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
  --data "mirror=true&import_url=https://username:token@gitlab.example.com/group/project.git" \
  --url "https://gitlab.example.com/api/v4/projects/:id"
```

Example removing pull mirroring:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "mirror=false" \
  --url "https://gitlab.example.com/api/v4/projects/:id"
```

## Start the pull mirroring process for a project

Start the pull mirroring process for a project.

```plaintext
POST /projects/:id/mirror/pull
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

If successful, returns [`202 Accepted`](rest/troubleshooting.md#status-codes).

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```

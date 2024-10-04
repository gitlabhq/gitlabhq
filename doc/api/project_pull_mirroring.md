---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Pull mirroring API

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

You can manage project [pull mirroring](../user/project/repository/mirror/pull.md) by using the REST API.

## Get a project's pull mirror details

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/354506) in GitLab 15.6.

Return the details of a project's [pull mirror](../user/project/repository/mirror/index.md).

```plaintext
GET /projects/:id/mirror/pull
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-paths). |

Example request:

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
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
  "url": "https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git"
}
```

## Configure pull mirroring for a project

> - Field `mirror_branch_regex` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/381667) in GitLab 15.8 [with a flag](../administration/feature_flags.md) named `mirror_only_branches_match_regex`. Disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/381667) in GitLab 16.0.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/410354) in GitLab 16.2. Feature flag `mirror_only_branches_match_regex` removed.

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
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
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
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
 --url "https://gitlab.example.com/api/v4/projects/:id" \
 --data "mirror=true&import_url=https://username:token@gitlab.example.com/group/project.git"
```

Example removing pull mirroring:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
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
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-paths). |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```

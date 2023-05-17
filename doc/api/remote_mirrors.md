---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
type: reference, api
---

# Project remote mirrors API **(FREE)**

[Push mirrors](../user/project/repository/mirror/push.md)
defined on a project's repository settings are called "remote mirrors". You
can query and modify the state of these mirrors with the remote mirror API.

For security reasons, the `url` attribute in the API response is always scrubbed of username
and password information.

NOTE:
[Pull mirrors](../user/project/repository/mirror/pull.md) use
[a different API endpoint](projects.md#configure-pull-mirroring-for-a-project) to
display and update them.

## List a project's remote mirrors

Returns an array of remote mirrors and their statuses:

```plaintext
GET /projects/:id/remote_mirrors
```

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/42/remote_mirrors"
```

Example response:

```json
[
  {
    "enabled": true,
    "id": 101486,
    "last_error": null,
    "last_successful_update_at": "2020-01-06T17:32:02.823Z",
    "last_update_at": "2020-01-06T17:32:02.823Z",
    "last_update_started_at": "2020-01-06T17:31:55.864Z",
    "only_protected_branches": true,
    "keep_divergent_refs": true,
    "update_status": "finished",
    "url": "https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git"
  }
]
```

## Get a single project's remote mirror

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/82770) in GitLab 14.10.

Returns a remote mirror and its statuses:

```plaintext
GET /projects/:id/remote_mirrors/:mirror_id
```

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486"
```

Example response:

```json
{
  "enabled": true,
  "id": 101486,
  "last_error": null,
  "last_successful_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_started_at": "2020-01-06T17:31:55.864Z",
  "only_protected_branches": true,
  "keep_divergent_refs": true,
  "update_status": "finished",
  "url": "https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git"
}
```

## Create a pull mirror

Learn how to [configure a pull mirror](projects.md#configure-pull-mirroring-for-a-project) using the Projects API.

## Create a push mirror

> - Field `mirror_branch_regex` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/381667) in GitLab 15.8 [with a flag](../administration/feature_flags.md) named `mirror_only_branches_match_regex`. Disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/381667) in GitLab 16.0.

FLAG:
On self-managed GitLab, by default the field `mirror_branch_regex` is available.
To hide the feature, ask an administrator to [disable the feature flag](../administration/feature_flags.md)
named `mirror_only_branches_match_regex`.
On GitLab.com, this feature is available.

Push mirroring is disabled by default. To enable it, include the optional parameter
`enabled` when you create the mirror:

```plaintext
POST /projects/:id/remote_mirrors
```

| Attribute                 | Type    | Required   | Description                                         |
| :----------               | :-----  | :--------- | :------------                                       |
| `url`                     | String  | yes        | The target URL to which the repository is mirrored. |
| `enabled`                 | Boolean | no         | Determines if the mirror is enabled.                |
| `keep_divergent_refs`     | Boolean | no         | Determines if divergent refs are skipped.           |
| `only_protected_branches` | Boolean | no         | Determines if only protected branches are mirrored. |
| `mirror_branch_regex` **(PREMIUM)**     | String  | no         | Contains a regular expression. Only branches with names matching the regex are mirrored. Requires `only_protected_branches` to be disabled. |

Example request:

```shell
curl --request POST --data "url=https://username:token@example.com/gitlab/example.git" \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/42/remote_mirrors"
```

Example response:

```json
{
    "enabled": false,
    "id": 101486,
    "last_error": null,
    "last_successful_update_at": null,
    "last_update_at": null,
    "last_update_started_at": null,
    "only_protected_branches": false,
    "keep_divergent_refs": false,
    "update_status": "none",
    "url": "https://*****:*****@example.com/gitlab/example.git"
}
```

## Update a remote mirror's attributes

FLAG:
On self-managed GitLab, by default the field `mirror_branch_regex` is not available.
To make it available, ask an administrator to [enable the feature flag](../administration/feature_flags.md)
named `mirror_only_branches_match_regex`.
On GitLab.com, this feature is not available.

Toggle a remote mirror on or off, or change which types of branches are
mirrored:

```plaintext
PUT /projects/:id/remote_mirrors/:mirror_id
```

| Attribute                 | Type    | Required   | Description                                         |
| :----------               | :-----  | :--------- | :------------                                       |
| `mirror_id`               | Integer | yes        | The remote mirror ID.                               |
| `enabled`                 | Boolean | no         | Determines if the mirror is enabled.                |
| `keep_divergent_refs`     | Boolean | no         | Determines if divergent refs are skipped.           |
| `only_protected_branches` | Boolean | no         | Determines if only protected branches are mirrored. |
| `mirror_branch_regex`**(PREMIUM)**     | String  | no         |  Determines if only the branch whose name matches the regex is mirrored. It does not work with `only_protected_branches` enabled. |

Example request:

```shell
curl --request PUT --data "enabled=false" --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486"
```

Example response:

```json
{
    "enabled": false,
    "id": 101486,
    "last_error": null,
    "last_successful_update_at": "2020-01-06T17:32:02.823Z",
    "last_update_at": "2020-01-06T17:32:02.823Z",
    "last_update_started_at": "2020-01-06T17:31:55.864Z",
    "only_protected_branches": true,
    "keep_divergent_refs": true,
    "update_status": "finished",
    "url": "https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git"
}
```

## Delete a remote mirror

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/82778) in GitLab 14.10.

Delete a remote mirror.

```plaintext
DELETE /projects/:id/remote_mirrors/:mirror_id
```

| Attribute   | Type    | Required   | Description       |
| :---------- | :-----  | :--------- |:------------------|
| `mirror_id` | Integer | yes        | Remote mirror ID. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486"
```

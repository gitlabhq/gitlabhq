---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, api
---

# Project remote mirrors API **(FREE)**

[Push mirrors](../user/project/repository/repository_mirroring.md#push-to-a-remote-repository)
defined on a project's repository settings are called "remote mirrors", and the
state of these mirrors can be queried and modified via the remote mirror API
outlined below.

## List a project's remote mirrors

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/38121) in GitLab 12.9.

Returns an Array of remote mirrors and their statuses:

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

NOTE:
For security reasons, the `url` attribute is always scrubbed of username
and password information.

## Create a remote mirror

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/24189) in GitLab 12.9.

Create a remote mirror for a project. The mirror is disabled by default. You can enable it by including the optional parameter `enabled` when creating it:

```plaintext
POST /projects/:id/remote_mirrors
```

| Attribute                 | Type    | Required   | Description                                         |
| :----------               | :-----  | :--------- | :------------                                       |
| `url`                     | String  | yes        | The URL of the remote repository to be mirrored.    |
| `enabled`                 | Boolean | no         | Determines if the mirror is enabled.                |
| `only_protected_branches` | Boolean | no         | Determines if only protected branches are mirrored. |
| `keep_divergent_refs`     | Boolean | no         | Determines if divergent refs are skipped.           |

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

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/38121) in GitLab 12.9.

Toggle a remote mirror on or off, or change which types of branches are
mirrored:

```plaintext
PUT /projects/:id/remote_mirrors/:mirror_id
```

| Attribute                 | Type    | Required   | Description                                         |
| :----------               | :-----  | :--------- | :------------                                       |
| `mirror_id`               | Integer | yes        | The remote mirror ID.                               |
| `enabled`                 | Boolean | no         | Determines if the mirror is enabled.                |
| `only_protected_branches` | Boolean | no         | Determines if only protected branches are mirrored. |
| `keep_divergent_refs`     | Boolean | no         | Determines if divergent refs are skipped.           |

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

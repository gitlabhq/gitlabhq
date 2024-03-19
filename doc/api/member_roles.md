---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Member roles API

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96996) in GitLab 15.4. [Deployed behind the `customizable_roles` flag](../administration/feature_flags.md), disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110810) in GitLab 15.9.
> - [Read vulnerability added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114734) in GitLab 16.0.
> - [Admin vulnerability added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121534) in GitLab 16.1.
> - [Read dependency added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126247) in GitLab 16.3.
> - [Name and description fields added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126423) in GitLab 16.3.
> - [Admin merge request introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128302) in GitLab 16.4 [with a flag](../administration/feature_flags.md) named `admin_merge_request`. Disabled by default.
> - [Feature flag `admin_merge_request` removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132578) in GitLab 16.5.
> - [Admin group members introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131914) in GitLab 16.5 [with a flag](../administration/feature_flags.md) named `admin_group_member`. Disabled by default. The feature flag has been removed in GitLab 16.6.
> - [Manage project access tokens introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132342) in GitLab 16.5 in [with a flag](../administration/feature_flags.md) named `manage_project_access_tokens`. Disabled by default.
> - [Archive project introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134998) in GitLab 16.7.
> - [Delete project introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139696) in GitLab 16.8.
> - [Manage group access tokens introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140115) in GitLab 16.8.
> - [Admin terraform state introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140759) in GitLab 16.8.

## List all member roles of a group

Gets a list of group member roles viewable by the authenticated user.

```plaintext
GET /groups/:id/member_roles
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) owned by the authenticated user |

If successful, returns [`200`](rest/index.md#status-codes) and the following response attributes:

| Attribute                          | Type    | Description           |
|:-----------------------------------|:--------|:----------------------|
| `[].id`                            | integer | The ID of the member role. |
| `[].name`                          | string  | The name of the member role. |
| `[].description`                   | string  | The description of the member role. |
| `[].group_id`                      | integer | The ID of the group that the member role belongs to. |
| `[].base_access_level`             | integer | Base access level for member role. Valid values are 10 (Guest), 20 (Reporter), 30 (Developer), 40 (Maintainer), or 50 (Owner).|
| `[].admin_merge_request`           | boolean | Permission to admin project merge requests and enables the ability to `download_code`. |
| `[].admin_terraform_state`         | boolean | Permission to admin project terraform state. |
| `[].admin_vulnerability`           | boolean | Permission to admin project vulnerabilities. |
| `[].read_code`                     | boolean | Permission to read project code. |
| `[].read_dependency`               | boolean | Permission to read project dependencies. |
| `[].read_vulnerability`            | boolean | Permission to read project vulnerabilities. |
| `[].admin_group_member`            | boolean | Permission to admin members of a group. |
| `[].manage_project_access_tokens`  | boolean | Permission to manage project access tokens. |
| `[].archive_project`               | boolean | Permission to archive projects. |
| `[].remove_project`                | boolean | Permission to delete projects. |
| `[].manage_group_access_tokens`    | boolean | Permission to manage group access tokens. |

Example request:

```shell
curl --header "Authorization: Bearer <your_access_token>" "https://gitlab.example.com/api/v4/groups/84/member_roles"
```

Example response:

```json
[
  {
    "id": 2,
    "name": "Custom + code",
    "description": "Custom guest that can read code",
    "group_id": 84,
    "base_access_level": 10,
    "admin_merge_request": false,
    "admin_terraform_state": false,
    "admin_vulnerability": false,
    "read_code": true,
    "read_dependency": false,
    "read_vulnerability": false,
    "manage_group_access_tokens": false,
    "manage_project_access_tokens": false,
    "archive_project": false,
    "remove_project": false
  },
  {
    "id": 3,
    "name": "Guest + security",
    "description": "Custom guest that read and admin security entities",
    "group_id": 84,
    "base_access_level": 10,
    "admin_vulnerability": true,
    "admin_merge_request": false,
    "admin_terraform_state": false,
    "read_code": false,
    "read_dependency": true,
    "read_vulnerability": true,
    "manage_group_access_tokens": false,
    "manage_project_access_tokens": false,
    "archive_project": false,
    "remove_project": false
  }
]
```

## Add a member role to a group

> - Ability to add a name and description when creating a custom role [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126423) in GitLab 16.3.

Adds a member role to a group.

```plaintext
POST /groups/:id/member_roles
```

To add a member role to a group, the group must be at root-level (have no parent group).

| Attribute | Type                | Required | Description |
| --------- | ------------------- | -------- | ----------- |
| `id`      | integer/string      | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `name`         | string         | yes      | The name of the member role. |
| `description`  | string         | no       | The description of the member role. |
| `base_access_level` | integer   | yes      | Base access level for configured role. Valid values are 10 (Guest), 20 (Reporter), 30 (Developer), 40 (Maintainer), or 50 (Owner).|
| `admin_merge_request` | boolean | no       | Permission to admin project merge requests. |
| `admin_terraform_state` | boolean | no       | Permission to admin project terraform state. |
| `admin_vulnerability` | boolean | no       | Permission to admin project vulnerabilities. |
| `read_code`           | boolean | no       | Permission to read project code. |
| `read_dependency`     | boolean | no       | Permission to read project dependencies. |
| `read_vulnerability`  | boolean | no       | Permission to read project vulnerabilities. |

If successful, returns [`201`](rest/index.md#status-codes) and the following attributes:

| Attribute                | Type     | Description           |
|:-------------------------|:---------|:----------------------|
| `id`                     | integer | The ID of the member role. |
| `name`                   | string  | The name of the member role. |
| `description`            | string  | The description of the member role. |
| `group_id`               | integer | The ID of the group that the member role belongs to. |
| `base_access_level`      | integer | Base access level for member role. |
| `admin_merge_request`    | boolean | Permission to admin project merge requests. |
| `admin_terraform_state`    | boolean | Permission to admin project terraform state. |
| `admin_vulnerability`    | boolean | Permission to admin project vulnerabilities. |
| `read_code`              | boolean | Permission to read project code. |
| `read_dependency`        | boolean | Permission to read project dependencies. |
| `read_vulnerability`     | boolean | Permission to read project vulnerabilities. |

Example request:

```shell
 curl --request POST --header "Content-Type: application/json" --header "Authorization: Bearer <your_access_token>" --data '{"name" : "Custom guest", "base_access_level" : 10, "read_code" : true}' "https://gitlab.example.com/api/v4/groups/84/member_roles"
```

Example response:

```json
{
  "id": 3,
  "name": "Custom guest",
  "description": null,
  "group_id": 84,
  "base_access_level": 10,
  "admin_merge_requests": false,
  "admin_vulnerability": false,
  "read_code": true,
  "read_dependency": false,
  "read_vulnerability": false
}
```

In GitLab 16.3 and later, you can use the API to:

- Add a name (required) and description (optional) when you
  [create a new custom role](../user/custom_roles.md#create-a-custom-role).
- Update an existing custom role's name and description.

### Remove member role of a group

Deletes a member role of a group.

```plaintext
DELETE /groups/:id/member_roles/:member_role_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `member_role_id` | integer | yes   | The ID of the member role. |

If successful, returns [`204`](rest/index.md#status-codes) and an empty response.

Example request:

```shell
curl --request DELETE --header "Content-Type: application/json" --header "Authorization: Bearer <your_access_token>" "https://gitlab.example.com/api/v4/groups/84/member_roles/1"
```

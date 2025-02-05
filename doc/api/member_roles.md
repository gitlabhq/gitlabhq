---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Member roles API
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed

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
> - Allow to create and remove an instance-wide custom role on GitLab Self-Managed [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141562) in GitLab 16.9.
> - [Admin security testing introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176628) in GitLab 17.9 [with a flag](../administration/feature_flags.md) named `custom_ability_admin_security_testing`. Disabled by default.

Use this API to interact with member roles for your GitLab.com groups or entire GitLab Self-Managed instance.

## Manage instance member roles

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Prerequisites:

- [Authenticate yourself](rest/authentication.md) as an administrator.

### Get all instance member roles

Get all member roles in an instance.

```plaintext
GET /member_roles
```

Example request:

```shell
curl --header "Authorization: Bearer <your_access_token>" "https://gitlab.example.com/api/v4/member_roles"
```

Example response:

```json
[
  {
    "id": 2,
    "name": "Instance custom role",
    "description": "Custom guest that can read code",
    "group_id": null,
    "base_access_level": 10,
    "admin_cicd_variables": false,
    "admin_compliance_framework": false,
    "admin_group_member": false,
    "admin_merge_request": false,
    "admin_push_rules": false,
    "admin_terraform_state": false,
    "admin_vulnerability": false,
    "admin_web_hook": false,
    "archive_project": false,
    "manage_deploy_tokens": false,
    "manage_group_access_tokens": false,
    "manage_merge_request_settings": false,
    "manage_project_access_tokens": false,
    "manage_security_policy_link": false,
    "read_code": true,
    "read_runners": false,
    "read_dependency": false,
    "read_vulnerability": false,
    "remove_group": false,
    "remove_project": false
  }
]
```

### Create a instance member role

Create an instance-wide member role.

```plaintext
POST /member_roles
```

Supported attributes:

| Attribute | Type | Required | Description |
|:----------|:--------|:---------|:-------------------------------------|
| `name`         | string         | yes      | The name of the member role. |
| `description`  | string         | no       | The description of the member role. |
| `base_access_level` | integer   | yes      | Base access level for configured role. Valid values are `10` (Guest), `15` (Planner), `20` (Reporter), `30` (Developer), `40` (Maintainer), or `50` (Owner).|
| `admin_cicd_variables` | boolean | no       | Permission to create, read, update, and delete CI/CD variables. |
| `admin_compliance_framework` | boolean | no       | Permission to administer compliance frameworks. |
| `admin_group_member` | boolean | no       | Permission to add, remove and assign members in a group. |
| `admin_merge_request` | boolean | no       | Permission to approve merge requests. |
| `admin_push_rules` | boolean | no       | Permission to configure push rules for repositories at group or project level. |
| `admin_terraform_state` | boolean | no       | Permission to administer project terraform state. |
| `admin_vulnerability` | boolean | no       | Permission to edit the vulnerability object, including the status and linking an issue. |
| `admin_web_hook` | boolean | no       | Permission to administer web hooks. |
| `archive_project` | boolean | no       | Permission to archive projects. |
| `manage_deploy_tokens` | boolean | no       | Permission to manage deploy tokens. |
| `manage_group_access_tokens` | boolean | no       | Permission to manage group access tokens. |
| `manage_merge_request_settings` | boolean | no       | Permission to configure merge request settings. |
| `manage_project_access_tokens` | boolean | no       | Permission to manage project access tokens. |
| `manage_security_policy_link` | boolean | no       | Permission to link security policy projects. |
| `read_code`           | boolean | no       | Permission to read project code. |
| `read_runners`     | boolean | no       | Permission to view project runners. |
| `read_dependency`     | boolean | no       | Permission to read project dependencies. |
| `read_vulnerability`  | boolean | no       | Permission to read project vulnerabilities. |
| `remove_group` | boolean | no       | Permission to delete or restore a group. |
| `remove_project` | boolean | no       | Permission to delete a project. |

For more information on available permissions, see [custom permissions](../user/custom_roles/abilities.md).

Example request:

```shell
 curl --request POST --header "Content-Type: application/json" --header "Authorization: Bearer <your_access_token>" --data '{"name" : "Custom guest (instance)", "base_access_level" : 10, "read_code" : true}' "https://gitlab.example.com/api/v4/member_roles"
```

Example response:

```json
{
  "id": 3,
  "name": "Custom guest (instance)",
  "group_id": null,
  "description": null,
  "base_access_level": 10,
  "admin_cicd_variables": false,
  "admin_compliance_framework": false,
  "admin_group_member": false,
  "admin_merge_request": false,
  "admin_push_rules": false,
  "admin_terraform_state": false,
  "admin_vulnerability": false,
  "admin_web_hook": false,
  "archive_project": false,
  "manage_deploy_tokens": false,
  "manage_group_access_tokens": false,
  "manage_merge_request_settings": false,
  "manage_project_access_tokens": false,
  "manage_security_policy_link": false,
  "read_code": true,
  "read_runners": false,
  "read_dependency": false,
  "read_vulnerability": false,
  "remove_group": false,
  "remove_project": false
}
```

### Delete an instance member role

Delete a member role from the instance.

```plaintext
DELETE /member_roles/:member_role_id
```

Supported attributes:

| Attribute | Type | Required | Description |
|:----------|:--------|:---------|:-------------------------------------|
| `member_role_id` | integer | yes   | The ID of the member role. |

If successful, returns [`204`](rest/troubleshooting.md#status-codes) and an empty response.

Example request:

```shell
curl --request DELETE --header "Content-Type: application/json" --header "Authorization: Bearer <your_access_token>" "https://gitlab.example.com/api/v4/member_roles/1"
```

## Manage group member roles

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com

Prerequisites:

- You must have the Owner role for the group.

### Get all group member roles

```plaintext
GET /groups/:id/member_roles
```

Supported attributes:

| Attribute | Type | Required | Description |
|:----------|:--------|:---------|:-------------------------------------|
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) of the group |

Example request:

```shell
curl --header "Authorization: Bearer <your_access_token>" "https://gitlab.example.com/api/v4/groups/84/member_roles"
```

Example response:

```json
[
  {
    "id": 2,
    "name": "Guest + read code",
    "description": "Custom guest that can read code",
    "group_id": 84,
    "base_access_level": 10,
    "admin_cicd_variables": false,
    "admin_compliance_framework": false,
    "admin_group_member": false,
    "admin_merge_request": false,
    "admin_push_rules": false,
    "admin_terraform_state": false,
    "admin_vulnerability": false,
    "admin_web_hook": false,
    "archive_project": false,
    "manage_deploy_tokens": false,
    "manage_group_access_tokens": false,
    "manage_merge_request_settings": false,
    "manage_project_access_tokens": false,
    "manage_security_policy_link": false,
    "read_code": true,
    "read_runners": false,
    "read_dependency": false,
    "read_vulnerability": false,
    "remove_group": false,
    "remove_project": false
  },
  {
    "id": 3,
    "name": "Guest + security",
    "description": "Custom guest that read and admin security entities",
    "group_id": 84,
    "base_access_level": 10,
    "admin_cicd_variables": false,
    "admin_compliance_framework": false,
    "admin_group_member": false,
    "admin_merge_request": false,
    "admin_push_rules": false,
    "admin_terraform_state": false,
    "admin_vulnerability": true,
    "admin_web_hook": false,
    "archive_project": false,
    "manage_deploy_tokens": false,
    "manage_group_access_tokens": false,
    "manage_merge_request_settings": false,
    "manage_project_access_tokens": false,
    "manage_security_policy_link": false,
    "read_code": true,
    "read_runners": false,
    "read_dependency": true,
    "read_vulnerability": true,
    "remove_group": false,
    "remove_project": false
  }
]
```

### Add a member role to a group

> - Ability to add a name and description when creating a custom role [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126423) in GitLab 16.3.

Adds a member role to a group. You can only add member roles at the root level of the group.

```plaintext
POST /groups/:id/member_roles
```

Parameters:

| Attribute | Type                | Required | Description |
|:----------|:--------|:---------|:-------------------------------------|
| `id`      | integer/string      | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) of the group. |
| `admin_cicd_variables` | boolean | no       | Permission to create, read, update, and delete CI/CD variables. |
| `admin_compliance_framework` | boolean | no       | Permission to administer compliance frameworks. |
| `admin_group_member` | boolean | no       | Permission to add, remove and assign members in a group. |
| `admin_merge_request` | boolean | no       | Permission to approve merge requests. |
| `admin_push_rules` | boolean | no       | Permission to configure push rules for repositories at group or project level. |
| `admin_terraform_state` | boolean | no       | Permission to admin project terraform state. |
| `admin_vulnerability` | boolean | no       | Permission to admin project vulnerabilities. |
| `admin_web_hook` | boolean | no       | Permission to administer web hooks. |
| `archive_project` | boolean | no       | Permission to archive projects. |
| `manage_deploy_tokens` | boolean | no       | Permission to manage deploy tokens. |
| `manage_group_access_tokens` | boolean | no       | Permission to manage group access tokens. |
| `manage_merge_request_settings` | boolean | no       | Permission to configure merge request settings. |
| `manage_project_access_tokens` | boolean | no       | Permission to manage project access tokens. |
| `manage_security_policy_link` | boolean | no       | Permission to link security policy projects. |
| `read_code`           | boolean | no       | Permission to read project code. |
| `read_runners`     | boolean | no       | Permission to view project runners. |
| `read_dependency`     | boolean | no       | Permission to read project dependencies. |
| `read_vulnerability`  | boolean | no       | Permission to read project vulnerabilities. |
| `remove_group` | boolean | no       | Permission to delete or restore a group. |
| `remove_project` | boolean | no       | Permission to delete a project. |

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
  "admin_cicd_variables": false,
  "admin_compliance_framework": false,
  "admin_group_member": false,
  "admin_merge_request": false,
  "admin_push_rules": false,
  "admin_terraform_state": false,
  "admin_vulnerability": false,
  "admin_web_hook": false,
  "archive_project": false,
  "manage_deploy_tokens": false,
  "manage_group_access_tokens": false,
  "manage_merge_request_settings": false,
  "manage_project_access_tokens": false,
  "manage_security_policy_link": false,
  "read_code": true,
  "read_runners": false,
  "read_dependency": false,
  "read_vulnerability": false,
  "remove_group": false,
  "remove_project": false
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
|:----------|:--------|:---------|:-------------------------------------|
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) of the group. |
| `member_role_id` | integer | yes   | The ID of the member role. |

If successful, returns [`204`](rest/troubleshooting.md#status-codes) and an empty response.

Example request:

```shell
curl --request DELETE --header "Content-Type: application/json" --header "Authorization: Bearer <your_access_token>" "https://gitlab.example.com/api/v4/groups/84/member_roles/1"
```

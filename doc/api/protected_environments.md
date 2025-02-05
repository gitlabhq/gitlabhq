---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Protected environments API
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

## Valid access levels

The access levels are defined in the `ProtectedEnvironments::DeployAccessLevel::ALLOWED_ACCESS_LEVELS` method.
Currently, these levels are recognized:

```plaintext
30 => Developer access
40 => Maintainer access
60 => Admin access
```

## Group inheritance types

Group inheritance allows deploy access levels and access rules to take inherited group membership into account. The group inheritance types are defined by `ProtectedEnvironments::Authorizable::GROUP_INHERITANCE_TYPE`.
The following types are recognized:

```plaintext
0 => Direct group membership only (default)
1 => All inherited groups
```

## List protected environments

Gets a list of protected environments from a project:

```plaintext
GET /projects/:id/protected_environments
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/protected_environments/"
```

Example response:

```json
[
   {
      "name":"production",
      "deploy_access_levels":[
         {
            "id": 12,
            "access_level":40,
            "access_level_description":"Maintainers",
            "user_id":null,
            "group_id":null,
            "group_inheritance_type": 0
         }
      ],
      "required_approval_count": 0
   }
]
```

## Get a single protected environment

Gets a single protected environment:

```plaintext
GET /projects/:id/protected_environments/:name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `name` | string | yes | The name of the protected environment |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/protected_environments/production"
```

Example response:

```json
{
   "name":"production",
   "deploy_access_levels":[
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "Maintainers",
         "user_id": null,
         "group_id": null,
         "group_inheritance_type": 0
      }
   ],
   "required_approval_count": 0
}
```

## Protect a single environment

Protects a single environment:

```plaintext
POST /projects/:id/protected_environments
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`                            | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `name`                          | string         | yes | The name of the environment. |
| `deploy_access_levels`          | array          | yes | Array of access levels allowed to deploy, with each described by a hash. |
| `approval_rules`                | array          | no  | Array of access levels allowed to approve, with each described by a hash. See [Multiple approval rules](../ci/environments/deployment_approvals.md#add-multiple-approval-rules). |

Elements in the `deploy_access_levels` and `approval_rules` array should be one of `user_id`, `group_id` or
`access_level`, and take the form `{user_id: integer}`, `{group_id: integer}` or
`{access_level: integer}`. Optionally, you can specify the `group_inheritance_type` on each as one of the [valid group inheritance types](#group-inheritance-types).

Each user must have access to the project and each group must [have this project shared](../user/project/members/sharing_projects_groups.md).

```shell
curl --header 'Content-Type: application/json' --request POST \
     --data '{"name": "production", "deploy_access_levels": [{"group_id": 9899826}], "approval_rules": [{"group_id": 134}, {"group_id": 135, "required_approvals": 2}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/22034114/protected_environments"
```

Example response:

```json
{
   "name": "production",
   "deploy_access_levels": [
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "protected-access-group",
         "user_id": null,
         "group_id": 9899826,
         "group_inheritance_type": 0
      }
   ],
   "required_approval_count": 0,
   "approval_rules": [
      {
         "id": 38,
         "user_id": null,
         "group_id": 134,
         "access_level": null,
         "access_level_description": "qa-group",
         "required_approvals": 1,
         "group_inheritance_type": 0
      },
      {
         "id": 39,
         "user_id": null,
         "group_id": 135,
         "access_level": null,
         "access_level_description": "security-group",
         "required_approvals": 2,
         "group_inheritance_type": 0
      }
   ]
}
```

## Update a protected environment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/351854) in GitLab 15.4.

Updates a single environment.

```plaintext
PUT /projects/:id/protected_environments/:name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`                            | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `name`                          | string         | yes | The name of the environment. |
| `deploy_access_levels`          | array          | no  | Array of access levels allowed to deploy, with each described by a hash. |
| `approval_rules`                | array          | no  | Array of access levels allowed to approve, with each described by a hash. See [Multiple approval rules](../ci/environments/deployment_approvals.md#add-multiple-approval-rules) for more information. |

Elements in the `deploy_access_levels` and `approval_rules` array should be one of `user_id`, `group_id` or
`access_level`, and take the form `{user_id: integer}`, `{group_id: integer}` or
`{access_level: integer}`. Optionally you can specify the `group_inheritance_type` on each as one of the [valid group inheritance types](#group-inheritance-types).

To update:

- **`user_id`**: Ensure the updated user has access to the project. You must also pass the `id` of either a `deploy_access_level` or `approval_rule` in the respective hash.
- **`group_id`**: Ensure the updated group [have this project shared](../user/project/members/sharing_projects_groups.md). You must also pass the `id` of either a `deploy_access_level` or `approval_rule` in the respective hash.

To delete:

- You must pass `_destroy` set to `true`. See the following examples.

### Example: Create a `deploy_access_level` record

```shell
curl --header 'Content-Type: application/json' --request PUT \
     --data '{"deploy_access_levels": [{"group_id": 9899829, access_level: 40}]' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
```

Example response:

```json
{
   "name": "production",
   "deploy_access_levels": [
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "protected-access-group",
         "user_id": null,
         "group_id": 9899829,
         "group_inheritance_type": 1
      }
   ],
   "required_approval_count": 0
}
```

### Example: Update a `deploy_access_level` record

```shell
curl --header 'Content-Type: application/json' --request PUT \
     --data '{"deploy_access_levels": [{"id": 12, "group_id": 22034120}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
```

```json
{
   "name": "production",
   "deploy_access_levels": [
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "protected-access-group",
         "user_id": null,
         "group_id": 22034120,
         "group_inheritance_type": 0
      }
   ],
   "required_approval_count": 2
}
```

### Example: Delete a `deploy_access_level` record

```shell
curl --header 'Content-Type: application/json' --request PUT \
     --data '{"deploy_access_levels": [{"id": 12, "_destroy": true}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
```

Example response:

```json
{
   "name": "production",
   "deploy_access_levels": [],
   "required_approval_count": 0
}
```

### Example: Create an `approval_rule` record

```shell
curl --header 'Content-Type: application/json' --request PUT \
     --data '{"approval_rules": [{"group_id": 134, "required_approvals": 1}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
```

Example response:

```json
{
   "name": "production",
   "approval_rules": [
      {
         "id": 38,
         "user_id": null,
         "group_id": 134,
         "access_level": null,
         "access_level_description": "qa-group",
         "required_approvals": 1,
         "group_inheritance_type": 0
      }
   ]
}
```

### Example: Update an `approval_rule` record

```shell
curl --header 'Content-Type: application/json' --request PUT \
     --data '{"approval_rules": [{"id": 38, "group_id": 135, "required_approvals": 2}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
```

```json
{
   "name": "production",
   "approval_rules": [
      {
         "id": 38,
         "user_id": null,
         "group_id": 135,
         "access_level": null,
         "access_level_description": "security-group",
         "required_approvals": 2,
         "group_inheritance_type": 0
      }
   ]
}
```

### Example: Delete an `approval_rule` record

```shell
curl --header 'Content-Type: application/json' --request PUT \
     --data '{"approval_rules": [{"id": 38, "_destroy": true}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
```

Example response:

```json
{
   "name": "production",
   "approval_rules": []
}
```

## Unprotect a single environment

Unprotects the given protected environment:

```plaintext
DELETE /projects/:id/protected_environments/:name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `name` | string | yes | The name of the protected environment. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/protected_environments/staging"
```

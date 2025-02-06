---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group-level protected environments API
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/215888) in GitLab 14.0. [Deployed behind the `group_level_protected_environments` flag](../administration/feature_flags.md), disabled by default.
> - [Feature flag `group_level_protected_environments`](https://gitlab.com/gitlab-org/gitlab/-/issues/331085) removed in GitLab 14.3.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/331085) in GitLab 14.3.

Read more about [group-level protected environments](../ci/environments/protected_environments.md#group-level-protected-environments).

## Valid access levels

The access levels are defined in the `ProtectedEnvironments::DeployAccessLevel::ALLOWED_ACCESS_LEVELS` method.
Currently, these levels are recognized:

```plaintext
30 => Developer access
40 => Maintainer access
60 => Admin access
```

## List group-level protected environments

Gets a list of protected environments from a group.

```plaintext
GET /groups/:id/protected_environments
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) maintained by the authenticated user. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/protected_environments/"
```

Example response:

```json
[
   {
      "name":"production",
      "deploy_access_levels":[
         {
            "id": 12,
            "access_level": 40,
            "access_level_description": "Maintainers",
            "user_id": null,
            "group_id": null
         }
      ],
      "required_approval_count": 0
   }
]
```

## Get a single protected environment

Gets a single protected environment.

```plaintext
GET /groups/:id/protected_environments/:name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) maintained by the authenticated user. |
| `name`    | string | yes    | The deployment tier of the protected environment. One of `production`, `staging`, `testing`, `development`, or `other`. Read more about [deployment tiers](../ci/environments/_index.md#deployment-tier-of-environments).|

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/protected_environments/production"
```

Example response:

```json
{
   "name":"production",
   "deploy_access_levels":[
      {
         "id": 12,
         "access_level":40,
         "access_level_description":"Maintainers",
         "user_id":null,
         "group_id":null
      }
   ],
   "required_approval_count": 0
}
```

## Protect a single environment

Protects a single environment.

```plaintext
POST /groups/:id/protected_environments
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) maintained by the authenticated user. |
| `name`    | string | yes    | The deployment tier of the protected environment. One of `production`, `staging`, `testing`, `development`, or `other`. Read more about [deployment tiers](../ci/environments/_index.md#deployment-tier-of-environments).|
| `deploy_access_levels`          | array          | yes | Array of access levels allowed to deploy, with each described by a hash. One of `user_id`, `group_id` or `access_level`. They take the form of `{user_id: integer}`, `{group_id: integer}` or `{access_level: integer}` respectively. |
| `approval_rules`                | array          | no  | Array of access levels allowed to approve, with each described by a hash. One of `user_id`, `group_id` or `access_level`. They take the form of `{user_id: integer}`, `{group_id: integer}` or `{access_level: integer}` respectively. You can also specify the number of required approvals from the specified entity with `required_approvals` field. See [Multiple approval rules](../ci/environments/deployment_approvals.md#add-multiple-approval-rules) for more information. |

The assignable `user_id` are the users who belong to the given group with the Maintainer role (or above).
The assignable `group_id` are the subgroups under the given group.

```shell
curl --header 'Content-Type: application/json' --request POST --data '{"name": "production", "deploy_access_levels": [{"group_id": 9899826}]}' --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/22034114/protected_environments"
```

Example response:

```json
{
   "name":"production",
   "deploy_access_levels":[
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "protected-access-group",
         "user_id": null,
         "group_id": 9899826
      }
   ],
   "required_approval_count": 0
}
```

An example with multiple approval rules:

```shell
curl --header 'Content-Type: application/json' --request POST \
     --data '{"name": "production", "deploy_access_levels": [{"group_id": 138}], "approval_rules": [{"group_id": 134}, {"group_id": 135, "required_approvals": 2}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/128/protected_environments"
```

In this configuration, the operator group `"group_id": 138` can execute the deployment job
to `production` only after the QA group `"group_id": 134` and security group
`"group_id": 135` have approved the deployment.

## Update a protected environment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/351854) in GitLab 15.4.

Updates a single environment.

```plaintext
PUT /groups/:id/protected_environments/:name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) maintained by the authenticated user. |
| `name`    | string | yes    | The deployment tier of the protected environment. One of `production`, `staging`, `testing`, `development`, or `other`. Read more about [deployment tiers](../ci/environments/_index.md#deployment-tier-of-environments).|
| `deploy_access_levels`          | array          | no | Array of access levels allowed to deploy, with each described by a hash. One of `user_id`, `group_id` or `access_level`. They take the form of `{user_id: integer}`, `{group_id: integer}` or `{access_level: integer}` respectively. |
| `required_approval_count` | integer        | no       | The number of approvals required to deploy to this environment. |
| `approval_rules`                | array          | no  | Array of access levels allowed to approve, with each described by a hash. One of `user_id`, `group_id` or `access_level`. They take the form of `{user_id: integer}`, `{group_id: integer}` or `{access_level: integer}` respectively. You can also specify the number of required approvals from the specified entity with `required_approvals` field. See [Multiple approval rules](../ci/environments/deployment_approvals.md#add-multiple-approval-rules) for more information. |

To update:

- **`user_id`**: Ensure the updated user belongs to the given group with the Maintainer role (or above). You must also pass the `id` of either a `deploy_access_level` or `approval_rule` in the respective hash.
- **`group_id`**: Ensure the updated group is a subgroup of the group this protected environment belongs to. You must also pass the `id` of either a `deploy_access_level` or `approval_rule` in the respective hash.

To delete:

- You must pass `_destroy` set to `true`. See the following examples.

### Example: Create a `deploy_access_level` record

```shell
curl --header 'Content-Type: application/json' --request PUT \
     --data '{"deploy_access_levels": [{"group_id": 9899829, access_level: 40}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production"
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
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production"
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
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production"
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
     "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production"
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
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production"
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
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production"
```

Example response:

```json
{
   "name": "production",
   "approval_rules": []
}
```

## Unprotect a single environment

Unprotects the given protected environment.

```plaintext
DELETE /groups/:id/protected_environments/:name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) maintained by the authenticated user. |
| `name`    | string | yes    | The deployment tier of the protected environment. One of `production`, `staging`, `testing`, `development`, or `other`. Read more about [deployment tiers](../ci/environments/_index.md#deployment-tier-of-environments).|

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/protected_environments/staging"
```

The response should return a 200 code.

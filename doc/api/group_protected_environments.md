---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: concepts, howto
---

# Group-level protected environments API **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/215888) in [GitLab Premium](https://about.gitlab.com/pricing/) 14.0.
> - [Deployed behind a feature flag](../user/feature_flags.md), disabled by default.
> - Disabled on GitLab.com.
> - Not recommended for production use.
> - To use in GitLab self-managed instances, ask a GitLab administrator to [enable it](../ci/environments/protected_environments.md#enable-or-disable-group-level-protected-environments). **(FREE SELF)**

This in-development feature might not be available for your use. There can be
[risks when enabling features still in development](../user/feature_flags.md#risks-when-enabling-features-still-in-development).
Refer to this feature's version history for more details.

Read more about [group-level protected environments](../ci/environments/protected_environments.md#group-level-protected-environments),

## Valid access levels

The access levels are defined in the `ProtectedEnvironment::DeployAccessLevel::ALLOWED_ACCESS_LEVELS` method.
Currently, these levels are recognized:

```plaintext
30 => Developer access
40 => Maintainer access
60 => Admin access
```

## List group-level protected environments

Gets a list of protected environments from a group.

```shell
GET /groups/:id/protected_environments
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) maintained by the authenticated user. |

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
            "access_level":40,
            "access_level_description":"Maintainers",
            "user_id":null,
            "group_id":null
         }
      ]
   }
]
```

## Get a single protected environment

Gets a single protected environment.

```shell
GET /groups/:id/protected_environments/:name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) maintained by the authenticated user. |
| `name`    | string | yes    | The deployment tier of the protected environment. One of `production`, `staging`, `testing`, `development`, or `other`. Read more about [deployment tiers](../ci/environments/index.md#deployment-tier-of-environments).|

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/protected_environments/production"
```

Example response:

```json
{
   "name":"production",
   "deploy_access_levels":[
      {
         "access_level":40,
         "access_level_description":"Maintainers",
         "user_id":null,
         "group_id":null
      }
   ]
}
```

## Protect an environment

Protects a single environment.

```shell
POST /groups/:id/protected_environments
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) maintained by the authenticated user. |
| `name`    | string | yes    | The deployment tier of the protected environment. One of `production`, `staging`, `testing`, `development`, or `other`. Read more about [deployment tiers](../ci/environments/index.md#deployment-tier-of-environments).|
| `deploy_access_levels`          | array          | yes | Array of access levels allowed to deploy, with each described by a hash. One of `user_id`, `group_id` or `access_level`. They take the form of `{user_id: integer}`, `{group_id: integer}` or `{access_level: integer}` respectively. |

The assignable `user_id` are the users who belong to the given group with the Maintainer role (or above).
The assignable `group_id` are the sub-groups under the given group.

```shell
curl --header 'Content-Type: application/json' --request POST --data '{"name": "production", "deploy_access_levels": [{"group_id": 9899826}]}' --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/22034114/protected_environments"
```

Example response:

```json
{
   "name":"production",
   "deploy_access_levels":[
      {
         "access_level":40,
         "access_level_description":"protected-access-group",
         "user_id":null,
         "group_id":9899826
      }
   ]
}
```

## Unprotect environment

Unprotects the given protected environment.

```shell
DELETE /groups/:id/protected_environments/:name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) maintained by the authenticated user. |
| `name`    | string | yes    | The deployment tier of the protected environment. One of `production`, `staging`, `testing`, `development`, or `other`. Read more about [deployment tiers](../ci/environments/index.md#deployment-tier-of-environments).|

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/protected_environments/staging"
```

The response should return a 200 code.

# Protected environments API **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30595) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.8.

## Valid access levels

The access levels are defined in the `ProtectedEnvironment::DeployAccessLevel::ALLOWED_ACCESS_LEVELS` method.
Currently, these levels are recognized:

```plaintext
30 => Developer access
40 => Maintainer access
60 => Admin access
```

## List protected environments

Gets a list of protected environments from a project:

```shell
GET /projects/:id/protected_environments
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |

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

Gets a single protected environment:

```shell
GET /projects/:id/protected_environments/:name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
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
         "access_level":40,
         "access_level_description":"Maintainers",
         "user_id":null,
         "group_id":null
      }
   ]
}
```

## Protect repository environments

Protects a single environment:

```shell
POST /projects/:id/protected_environments
```

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/protected_environments?name=staging&deploy_access_levels%5B%5D%5Buser_id%5D=1"
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`                            | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
| `name`                          | string         | yes | The name of the environment. |
| `deploy_access_levels`          | array          | yes | Array of access levels allowed to deploy, with each described by a hash. |

Elements in the `deploy_access_levels` array should take the
form `{user_id: integer}`, `{group_id: integer}` or `{access_level: integer}`.
Each user must have access to the project and each group must [have this project shared](../user/project/members/share_project_with_groups.md).

Example response:

```json
{
   "name":"staging",
   "deploy_access_levels":[
      {
         "access_level":null,
         "access_level_description":"Administrator",
         "user_id":1,
         "group_id":null
      }
   ]
}
```

## Unprotect environment

Unprotects the given protected environment:

```shell
DELETE /projects/:id/protected_environments/:name
```

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/protected_environments/staging"
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
| `name` | string | yes | The name of the protected environment. |

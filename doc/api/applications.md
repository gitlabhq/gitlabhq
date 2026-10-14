---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Applications API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to manage instance-wide OAuth applications that:

- [Use GitLab as an authentication provider](../integration/oauth_provider.md).
- [Allow access to GitLab resources on a user's behalf](oauth2.md).

> [!note]
> You cannot use this API to manage group applications or individual user applications.

Prerequisites:

- You must have administrator access to the instance.

## Create an application

{{< history >}}

- `granular_scopes` attribute [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/631825) in GitLab 19.6 [with a feature flag](../administration/feature_flags/_index.md) named `granular_oauth_tokens`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of the `granular_scopes` attribute is controlled by a feature flag. For more information, see the history.

Creates an application.

Returns `200` if the request succeeds.

```plaintext
POST /applications
```

Supported attributes:

| Attribute      | Type    | Required | Description                      |
|:---------------|:--------|:---------|:---------------------------------|
| `name`         | string  | yes      | Name of the application.         |
| `redirect_uri` | string  | yes      | Redirect URI of the application. |
| `scopes`       | string  | yes      | Scopes available to the application. Separate multiple scopes with a space. |
| `confidential` | boolean | no       | If `true`, the application can securely store client credentials, such as the client secret. Non-confidential applications (such as native mobile apps and Single Page Apps) might expose client credentials. Defaults to `true` if unspecified. |
| `granular_scopes` | array | no | Granular scopes to declare on the application, each pairing an access level with a list of permissions. |
| `granular_scopes[].access` | string | yes | Access level of the scope. One of `user`, `instance`, `all_memberships`, or `selected_memberships`. |
| `granular_scopes[].permissions` | array of strings | yes | Names of the permissions the scope grants, for example `execute_mcp_tool` or `read_member_role`. |
| `granular_scopes[].group_ids` | array of integers | no | IDs of the groups the scope applies to. Used only when `access` is `selected_memberships`. |
| `granular_scopes[].project_ids` | array of integers | no | IDs of the projects the scope applies to. Used only when `access` is `selected_memberships`. |

Declaring granular scopes records which fine-grained permissions the application has, as a set of access levels and permissions. GitLab creates the application and stores this set together in one step. If GitLab rejects the set, it does not create the application.

Example request:

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --data "name=MyApplication&redirect_uri=http://redirect.uri&scopes=api read_user email" \
    --url "https://gitlab.example.com/api/v4/applications"
```

Example response:

```json
{
    "id":1,
    "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
    "application_name": "MyApplication",
    "secret": "ee1dd64b6adc89cf7e2c23099301ccc2c61b441064e9324d963c46902a85ec34",
    "callback_url": "http://redirect.uri",
    "confidential": true,
    "scopes": ["api", "read_user", "email"]
}
```

Example request with granular scopes:

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --header "Content-Type: application/json" \
    --data '{"name": "MyApplication", "redirect_uri": "http://redirect.uri", "scopes": "api", "granular_scopes": [{"access": "user", "permissions": ["execute_mcp_tool"]}, {"access": "selected_memberships", "permissions": ["read_member_role"], "group_ids": [5]}]}' \
    --url "https://gitlab.example.com/api/v4/applications"
```

The response adds these attributes:

| Attribute | Type | Description |
|:----------|:-----|:------------|
| `granular_scopes` | array | Granular scopes stored on the application, each with `access`, `permissions`, `group_id`, and `project_id`. |
| `granular_scopes[].group_id` | integer | ID of the group when the scope targets a group, otherwise `null`. |
| `granular_scopes[].project_id` | integer | ID of the project when the scope targets a project, otherwise `null`. |
| `warnings` | array of strings | Warnings returned when no `user` scope grants `execute_mcp_tool`. Tokens for such an application cannot use the GitLab MCP server. |

While an application has granular scopes, GitLab adds the `granular` scope to its `scopes`.

Example response:

```json
{
    "id": 2,
    "application_id": "0a9c3b1f2e4d5c6b7a8f9e0d1c2b3a4f5e6d7c8b9a0f1e2d3c4b5a6f7e8d9c0b",
    "application_name": "MyApplication",
    "secret": "<application_secret>",
    "callback_url": "http://redirect.uri",
    "confidential": true,
    "scopes": ["api", "granular"],
    "granular_scopes": [
        { "access": "user", "permissions": ["execute_mcp_tool"], "project_id": null, "group_id": null },
        { "access": "selected_memberships", "permissions": ["read_member_role"], "project_id": null, "group_id": 5 }
    ]
}
```

## List all applications

Lists all applications.

```plaintext
GET /applications
```

Example request:

```shell
curl --request GET \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/applications"
```

Example response:

```json
[
    {
        "id":1,
        "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
        "application_name": "MyApplication",
        "callback_url": "http://redirect.uri",
        "confidential": true,
        "scopes": ["api", "read_user"]
    }
]
```

> [!note]
> The `secret` value is not exposed by this API.

## Delete an application

Deletes a specified application.

Returns `204` if the request succeeds.

```plaintext
DELETE /applications/:id
```

Supported attributes:

| Attribute | Type    | Required | Description                                         |
|:----------|:--------|:---------|:----------------------------------------------------|
| `id`      | integer | yes      | The ID of the application (not the `application_id`). |

Example request:

```shell
curl --request DELETE \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/applications/:id"
```

## Renew an application secret

Renews the secret for a specified application. Returns `200` if the request succeeds.

```plaintext
POST /applications/:id/renew-secret
```

Supported attributes:

| Attribute | Type    | Required | Description                                         |
|:----------|:--------|:---------|:----------------------------------------------------|
| `id`      | integer | yes      | The ID of the application (not the `application_id`). |

Example request:

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/applications/:id/renew-secret"
```

Example response:

```json
{
    "id":1,
    "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
    "application_name": "MyApplication",
    "secret": "ee1dd64b6adc89cf7e2c23099301ccc2c61b441064e9324d963c46902a85ec34",
    "callback_url": "http://redirect.uri",
    "confidential": true,
    "scopes": ["api", "read_user"]
}
```

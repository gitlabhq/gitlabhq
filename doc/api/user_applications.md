---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: User Applications API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to manage user-level OAuth applications that:

- [Use GitLab as an authentication provider](../integration/oauth_provider.md).
- [Allow access to GitLab resources on a user's behalf](oauth2.md).

> [!note]
> To manage instance-wide applications, use the [Applications API](applications.md).

Prerequisites:

- Administrator access or authenticated as the user who owns the application.

## Create an application

Creates a new OAuth application for the authenticated user.

Returns `201` if the request succeeds.

```plaintext
POST /user/applications
```

Supported attributes:

| Attribute      | Type    | Required | Description                      |
|:---------------|:--------|:---------|:---------------------------------|
| `name`         | string  | yes      | Name of the application.         |
| `redirect_uri` | string  | yes      | Redirect URI of the application. |
| `scopes`       | string  | yes      | Scopes available to the application. Separate multiple scopes with a space. |
| `confidential` | boolean | no       | If `true`, the application can securely store client credentials, such as the client secret. Non-confidential applications (such as native mobile apps and Single Page Apps) might expose client credentials. If unspecified, defaults to `true`. |

Example request:

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --data "name=MyApplication&redirect_uri=http://redirect.uri&scopes=api read_user email" \
    --url "https://gitlab.example.com/api/v4/user/applications"
```

Example response:

```json
{
    "id":1,
    "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
    "application_name": "MyApplication",
    "secret": "ee1dd64b6adc89cf7e2c23099301ccc2c61b441064e9324d963c46902a85ec34",
    "callback_url": "http://redirect.uri",
    "confidential": true
}
```

## List all applications

Lists all applications owned by the authenticated user.

```plaintext
GET /user/applications
```

Example request:

```shell
curl --request GET \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/user/applications"
```

Example response:

```json
[
    {
        "id":1,
        "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
        "application_name": "MyApplication",
        "callback_url": "http://redirect.uri",
        "confidential": true
    }
]
```

## Retrieve a specific application

Retrieves details of a specific application owned by the authenticated user.

Returns `200` if the request succeeds.

```plaintext
GET /user/applications/:id
```

Supported attributes:

| Attribute | Type    | Required | Description                                         |
|:----------|:--------|:---------|:----------------------------------------------------|
| `id`      | integer | yes      | ID of the application. Differs from the `application_id`.' |

Example request:

```shell
curl --request GET \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/user/applications/:id"
```

Example response:

```json
{
    "id":1,
    "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
    "application_name": "MyApplication",
    "callback_url": "http://redirect.uri",
    "confidential": true
}
```

## Update an application

Updates an existing application owned by the authenticated user.

Returns `200` if the request succeeds.

```plaintext
PUT /user/applications/:id
```

Supported attributes:

| Attribute      | Type    | Required | Description                      |
|:---------------|:--------|:---------|:---------------------------------|
| `id`           | integer | yes      | ID of the application. Differs from the `application_id`.' |
| `name`         | string  | no       | Name of the application.         |
| `scopes`       | string  | no       | Scopes available to the application. Separate multiple scopes with a space. |

Example request:

```shell
curl --request PUT \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --data "name=UpdatedApplication" \
    --url "https://gitlab.example.com/api/v4/user/applications/:id"
```

Example response:

```json
{
    "id":1,
    "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
    "application_name": "UpdatedApplication",
    "callback_url": "http://redirect.uri",
    "confidential": true
}
```

## Delete an application

Deletes a specified application owned by the authenticated user.

Returns `204` if the request succeeds.

```plaintext
DELETE /user/applications/:id
```

Supported attributes:

| Attribute | Type    | Required | Description                                         |
|:----------|:--------|:---------|:----------------------------------------------------|
| `id`      | integer | yes      | ID of the application. Differs from the `application_id`.' |

Example request:

```shell
curl --request DELETE \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/user/applications/:id"
```

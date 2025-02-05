---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Applications API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use this API to interact instance-wide OAuth applications for:

- [Using GitLab as an authentication provider](../integration/oauth_provider.md).
- [Allowing access to GitLab resources on a user's behalf](oauth2.md).

NOTE:
You cannot use this API to manage group applications or individual user applications.

Prerequisites:

- You must have administrator access to the instance.

## Create an application

Create an application by posting a JSON payload.

Returns `200` if the request succeeds.

```plaintext
POST /applications
```

Supported attributes:

| Attribute      | Type    | Required | Description                      |
|:---------------|:--------|:---------|:---------------------------------|
| `name`         | string  | yes      | Name of the application.         |
| `redirect_uri` | string  | yes      | Redirect URI of the application. |
| `scopes`       | string  | yes      | Scopes of the application. You can specify multiple scopes by separating each scope using a space. |
| `confidential` | boolean | no       | The application is used where the client secret can be kept confidential. Native mobile apps and Single Page Apps are considered non-confidential. Defaults to `true` if not supplied |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "name=MyApplication&redirect_uri=http://redirect.uri&scopes=api read_user email" \
     "https://gitlab.example.com/api/v4/applications"
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

List all registered applications.

```plaintext
GET /applications
```

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/applications"
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

NOTE:
The `secret` value is not exposed by this API.

## Delete an application

Delete a specific application.

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
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/applications/:id"
```

## Renew an application secret

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/422420) in GitLab 16.11.

Renews an application secret. Returns `200` if the request succeeds.

```plaintext
POST /applications/:id/renew-secret
```

Supported attributes:

| Attribute | Type    | Required | Description                                         |
|:----------|:--------|:---------|:----------------------------------------------------|
| `id`      | integer | yes      | The ID of the application (not the `application_id`). |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/applications/:id/renew-secret"
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

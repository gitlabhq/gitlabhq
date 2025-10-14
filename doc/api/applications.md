---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Applications API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to manage instance-wide OAuth applications that:

- [Use GitLab as an authentication provider](../integration/oauth_provider.md).
- [Allow access to GitLab resources on a user's behalf](oauth2.md).

{{< alert type="note" >}}

You cannot use this API to manage group applications or individual user applications.

{{< /alert >}}

Prerequisites:

- You must have administrator access to the instance.

## Create an application

Creates an application by posting a JSON payload.

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
    "confidential": true
}
```

## List all applications

Lists all registered applications.

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
        "confidential": true
    }
]
```

{{< alert type="note" >}}

The `secret` value is not exposed by this API.

{{< /alert >}}

## Delete an application

Deletes a registered application.

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

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/422420) in GitLab 16.11.

{{< /history >}}

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
    "confidential": true
}
```

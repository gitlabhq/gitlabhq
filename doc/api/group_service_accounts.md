---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group service accounts API
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to interact with service accounts for your groups. For more information, see [Service accounts](../user/profile/service_accounts.md).

Prerequisites:

- You must have administrator access to the instance, or have the Owner role for the GitLab.com group.

## List all service account users

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416729) in GitLab 17.1.

{{< /history >}}

Lists all service account users in a specified top-level group.

Use the `page` and `per_page` [pagination parameters](rest/_index.md#offset-based-pagination) to filter the results.

```plaintext
GET /groups/:id/service_accounts
```

Parameters:

| Attribute    | Type     | Required   | Description                                                     |
|:-------------|:---------|:-----------|:----------------------------------------------------------------|
| `id`         | integer/string | yes  | The ID or [URL-encoded path of the target group](rest/_index.md#namespaced-paths). |
| `order_by`   | string   | no         | Orders list of users by `username` or `id`. Default is `id`.    |
| `sort`       | string   | no         | Specifies sorting by `asc` or `desc`. Default is `desc`.        |

Example request:

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/345/service_accounts"
```

Example response:

```json
[

  {
    "id": 57,
    "username": "service_account_group_345_<random_hash>",
    "name": "Service account user",
    "email": "service_account_group_345_<random_hash>@noreply.gitlab.example.com"
  },
  {
    "id": 58,
    "username": "service_account_group_346_<random_hash>",
    "name": "Service account user",
    "email": "service_account_group_346_<random_hash>@noreply.gitlab.example.com"
  }
]
```

## Create a service account user

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/407775) in GitLab 16.1.
- Specify a service account user username or name was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144841) in GitLab 16.10.
- Specify a service account user email address was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181456) in GitLab 17.9 [with a flag](../administration/feature_flags.md) named `group_service_account_custom_email`.

{{< /history >}}

Creates a service account user in a given top-level group.

{{< alert type="note" >}}

This endpoint only works on top-level groups.

{{< /alert >}}

```plaintext
POST /groups/:id/service_accounts
```

Supported attributes:

| Attribute  | Type           | Required | Description                                                                                                                                                                                                                                                                                   |
|:-----------|:---------------|:---------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`       | integer/string | yes | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of a top-level group.                                                                                                                                                                                                               |
| `name`     | string         | no  | User account name. If not specified, uses `Service account user`.                                                                                                                                                                                                                             |
| `username` | string         | no  | User account username. If not specified, generates a name prepended with `service_account_group_`.                                                                                                                                                                                            |
| `email`    | string         | no  | User account email. If not specified, generates an email prepended with `service_account_group_`. Custom email addresses require confirmation before the account is active, unless the group has a matching [verified domain](../user/enterprise_user/_index.md#verified-domains-for-groups). |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/345/service_accounts" --data "email=custom_email@example.com"
```

Example response:

```json
{
  "id": 57,
  "username": "service_account_group_345_6018816a18e515214e0c34c2b33523fc",
  "name": "Service account user",
  "email": "custom_email@example.com"
}
```

## Update a service account user

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182607/) in GitLab 17.10.

{{< /history >}}

Updates a service account user in a given top-level group.

{{< alert type="note" >}}

This endpoint only works on top-level groups.

{{< /alert >}}

```plaintext
PATCH /groups/:id/service_accounts/:user_id
```

Parameters:

| Attribute  | Type           | Required | Description                                                     |
|:-----------|:---------------|:---------|:----------------------------------------------------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the target group](rest/_index.md#namespaced-paths). |
| `user_id`  | integer        | yes      | The ID of the service account user.                              |
| `name`     | string         | no       | Name of the user.                                               |
| `username` | string         | no       | Username of the user.                                           |

Example request:

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/345/service_accounts/57" --data "name=Updated Service Account"
```

Example response:

```json
{
  "id": 57,
  "username": "service_account_group_345_6018816a18e515214e0c34c2b33523fc",
  "name": "Updated Service Account",
  "email": "service_account_group_345_<random_hash>@noreply.gitlab.example.com"
}
```

## Delete a service account user

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416729) in GitLab 17.1.

{{< /history >}}

Deletes a service account user from a given top-level group.

{{< alert type="note" >}}

This endpoint only works on top-level groups.

{{< /alert >}}

```plaintext
DELETE /groups/:id/service_accounts/:user_id
```

Parameters:

| Attribute                  | Type           | Required                  | Description                                                                    |
|:---------------------------|:---------------|:--------------------------|:-------------------------------------------------------------------------------|
| `id`          | integer/string | yes  | The ID or [URL-encoded path of the target group](rest/_index.md#namespaced-paths). |
| `user_id`     | integer | yes      | The ID of a service account user.                            |
| `hard_delete` | boolean | no       | If true, contributions that would usually be [moved to a Ghost User](../user/profile/account/delete_account.md#associated-records) are instead deleted, as well as groups owned solely by this service account user. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/345/service_accounts/181"
```

## List all personal access tokens for a service account user

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/526924) in GitLab 17.11.

{{< /history >}}

Lists all personal access tokens for a service account user in a top-level group.

```plaintext
GET /groups/:id/service_accounts/:user_id/personal_access_tokens
```

Supported attributes:

| Attribute          | Type                | Required | Description |
| ------------------ | ------------------- | -------- | ----------- |
| `id`      | integer/string | yes  | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of a top-level group. |
| `user_id` | integer | yes      | ID of service account user. |
| `created_after`    | datetime (ISO 8601) | No       | If defined, returns tokens created after the specified time. |
| `created_before`   | datetime (ISO 8601) | No       | If defined, returns tokens created before the specified time. |
| `expires_after`    | date (ISO 8601)     | No       | If defined, returns tokens that expire after the specified time. |
| `expires_before`   | date (ISO 8601)     | No       | If defined, returns tokens that expire before the specified time. |
| `last_used_after`  | datetime (ISO 8601) | No       | If defined, returns tokens last used after the specified time. |
| `last_used_before` | datetime (ISO 8601) | No       | If defined, returns tokens last used before the specified time. |
| `revoked`          | boolean             | No       | If `true`, only returns revoked tokens. |
| `search`           | string              | No       | If defined, returns tokens that include the specified value in the name. |
| `sort`             | string              | No       | If defined, sorts the results by the specified value. Possible values: `created_asc`, `created_desc`, `expires_before_asc`, `expires_after_desc`, `last_used_before_asc`, `last_used_after_desc`, `name_asc`, `name_desc`. |
| `state`            | string              | No       | If defined, returns tokens with the specified state. Possible values: `active` and `inactive`. |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/187/service_accounts/195/personal_access_tokens?sort=id_desc&search=token2b&created_before=2025-03-27"
```

Example response:

```json
[
    {
        "id": 187,
        "name": "service_accounts_token2b",
        "revoked": false,
        "created_at": "2025-03-26T14:42:51.084Z",
        "description": null,
        "scopes": [
            "api"
        ],
        "user_id": 195,
        "last_used_at": null,
        "active": true,
        "expires_at": null
    }
]
```

Example of unsuccessful responses:

- `401: Unauthorized`
- `404 Personal access token(s) Not Found`

## Create a personal access token for a service account user

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/406781) in GitLab 16.1.

{{< /history >}}

Creates a personal access token for an existing service account user in a given top-level group.

```plaintext
POST /groups/:id/service_accounts/:user_id/personal_access_tokens
```

Parameters:

| Attribute | Type            | Required | Description |
| --------- | --------------- | -------- | ----------- |
| `id`      | integer/string | yes  | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of a top-level group. |
| `user_id` | integer | yes      | ID of service account user.                            |
| `name`    | string  | yes      | Name of personal access token. |
| `description` | string  | no   | Description of personal access token. |
| `scopes`  | array   | yes      | Array of approved scopes. For a list of possible values, see [Personal access token scopes](../user/profile/personal_access_tokens.md#personal-access-token-scopes). |
| `expires_at` | date    | no       | Expiration date of the access token in ISO format (`YYYY-MM-DD`). If not specified, the date is set to the [maximum allowable lifetime limit](../user/profile/personal_access_tokens.md#access-token-expiration). |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/35/service_accounts/71/personal_access_tokens" --data "scopes[]=api,read_user,read_repository" --data "name=service_accounts_token"
```

Example response:

```json
{
  "id":6,
  "name":"service_accounts_token",
  "revoked":false,
  "created_at":"2023-06-13T07:47:13.900Z",
  "scopes":["api"],
  "user_id":71,
  "last_used_at":null,
  "active":true,
  "expires_at":"2024-06-12",
  "token":"<token_value>"
}
```

## Revoke a personal access token for a service account user

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184287) in GitLab 17.10

{{< /history >}}

Revokes a personal access token for an existing service account user in a given top-level group.

{{< alert type="note" >}}

This endpoint only works on top-level groups.

{{< /alert >}}

```plaintext
DELETE /groups/:id/service_accounts/:user_id/personal_access_tokens/:token_id
```

Parameters:

| Attribute    | Type            | Required | Description |
| ------------ | --------------- | -------- | ----------- |
| `id`         | integer/string | yes  | The ID or [URL-encoded path of the target group](rest/_index.md#namespaced-paths). |
| `user_id`    | integer | yes      | The ID of the service account user.                            |
| `token_id`   | integer | yes      | The ID of the token. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/35/service_accounts/71/personal_access_tokens/6"
```

If successful, returns `204: No Content`.

Other possible responses:

- `400: Bad Request` if not revoked successfully.
- `401: Unauthorized` if the request is not authorized.
- `403: Forbidden` if the request is not allowed.
- `404: Not Found` if the access token does not exist.

## Rotate a personal access token for a service account user

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/406781) in GitLab 16.1.

{{< /history >}}

Rotates a personal access token for an existing service account user in a given top-level group. This creates a new token valid for one week and revokes any existing tokens.

{{< alert type="note" >}}

This endpoint only works on top-level groups.

{{< /alert >}}

```plaintext
POST /groups/:id/service_accounts/:user_id/personal_access_tokens/:token_id/rotate
```

Parameters:

| Attribute    | Type            | Required | Description |
| ------------ | --------------- | -------- | ----------- |
| `id`         | integer/string | yes  | The ID or [URL-encoded path of the target group](rest/_index.md#namespaced-paths). |
| `user_id`    | integer | yes      | The ID of the service account user.                            |
| `token_id`   | integer | yes      | The ID of the token. |
| `expires_at` | date   | no        | Expiration date of the access token in ISO format (`YYYY-MM-DD`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/505671) in GitLab 17.9. If undefined, the token expires after one week. |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/35/service_accounts/71/personal_access_tokens/6/rotate"
```

Example response:

```json
{
  "id":7,
  "name":"service_accounts_token",
  "revoked":false,
  "created_at":"2023-06-13T07:54:49.962Z",
  "scopes":["api"],
  "user_id":71,
  "last_used_at":null,
  "active":true,
  "expires_at":"2023-06-20",
  "token":"<token_value>"
}
```

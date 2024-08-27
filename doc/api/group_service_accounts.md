---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Group service accounts

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Interact with [service accounts](../user/profile/service_accounts.md) by using the REST API.

Prerequisites:

- You must be an administrator of the self-managed instance, or have the Owner role for the GitLab.com group.

## List service account users

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416729) in GitLab 17.1.

Lists all service account users that are provisioned by group.

This function takes pagination parameters `page` and `per_page` to restrict the list of users.

```plaintext
GET /groups/:id/service_accounts
```

Parameters:

| Attribute    | Type     | Required   | Description                                                     |
|:-------------|:---------|:-----------|:----------------------------------------------------------------|
| `id`         | integer/string | yes  | The ID or [URL-encoded path of the target group](rest/index.md#namespaced-path-encoding). |
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
    "name": "Service account user"
  },
  {
    "id": 58,
    "username": "service_account_group_346_<random_hash>",
    "name": "Service account user"
  }
]
```

## Create a service account user

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/407775) in GitLab 16.1.
> - Ability to specify a username or name was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144841) in GitLab 16.10.

Creates a service account user.

This API endpoint works on top-level groups only. It does not work on subgroups.

```plaintext
POST /groups/:id/service_accounts
```

Supported attributes:

| Attribute                  | Type           | Required                  | Description                                                                    |
|:---------------------------|:---------------|:--------------------------|:-------------------------------------------------------------------------------|
| `id`         | integer/string | yes  | The ID or [URL-encoded path of the target group](rest/index.md#namespaced-path-encoding). |
| `name`       | string | no | The name of the user. If not specified, the default `Service account user` name is used. |
| `username`   | string | no | The username of the user. If not specified, it's automatically generated. |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/345/service_accounts"
```

Example response:

```json
{
  "id": 57,
  "username": "service_account_group_345_6018816a18e515214e0c34c2b33523fc",
  "name": "Service account user"
}
```

## Delete a service account user

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416729) in GitLab 17.1.

Deletes a service account user.

This API endpoint works on top-level groups only. It does not work on subgroups.

```plaintext
DELETE /groups/:id/service_accounts/:user_id
```

Parameters:

| Attribute                  | Type           | Required                  | Description                                                                    |
|:---------------------------|:---------------|:--------------------------|:-------------------------------------------------------------------------------|
| `id`          | integer/string | yes  | The ID or [URL-encoded path of the target group](rest/index.md#namespaced-path-encoding). |
| `user_id`     | integer | yes      | The ID of a service account user.                            |
| `hard_delete` | boolean | no       | If true, contributions that would usually be [moved to a Ghost User](../user/profile/account/delete_account.md#associated-records) are instead deleted, as well as groups owned solely by this service account user. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/345/service_accounts/181"
```

## Create a personal access token for a service account user

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/406781) in GitLab 16.1.

This API endpoint works on top-level groups only. It does not work on subgroups.

```plaintext
POST /groups/:id/service_accounts/:user_id/personal_access_tokens
```

Parameters:

| Attribute | Type            | Required | Description |
| --------- | --------------- | -------- | ----------- |
| `id`      | integer/string | yes  | The ID or [URL-encoded path of the target group](rest/index.md#namespaced-path-encoding). |
| `user_id` | integer | yes      | The ID of a service account user.                            |
| `name`    | string  | yes      | The name of the personal access token. |
| `scopes`  | array   | yes      | Array of scopes of the personal access token. See [personal access token scopes](../user/profile/personal_access_tokens.md#personal-access-token-scopes) for possible values. |
| `expires_at` | date | no      | The personal access token expiry date. When left blank, the token follows the [standard rule of expiry for personal access tokens](../user/profile/personal_access_tokens.md#when-personal-access-tokens-expire). |

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

## Rotate a personal access token for a service account user

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/406781) in GitLab 16.1.

This API endpoint works on top-level groups only. It does not work on subgroups.

```plaintext
POST /groups/:id/service_accounts/:user_id/personal_access_tokens/:token_id/rotate
```

Parameters:

| Attribute | Type            | Required | Description |
| --------- | --------------- | -------- | ----------- |
| `id`         | integer/string | yes  | The ID or [URL-encoded path of the target group](rest/index.md#namespaced-path-encoding). |
| `user_id`    | integer | yes      | The ID of the service account user.                            |
| `token_id`   | integer | yes      | The ID of the token. |

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

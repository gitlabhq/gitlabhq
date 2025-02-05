---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group service accounts API
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use this API to interact with service accounts for your groups. For more information, see [Service accounts](../user/profile/service_accounts.md).

Prerequisites:

- You must have administrator access to the instance, or have the Owner role for the GitLab.com group.

## List all service account users

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416729) in GitLab 17.1.

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
> - Specify a service account user username or name was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144841) in GitLab 16.10.

Creates a service account user in a given top-level group.

NOTE:
This endpoint only works on top-level groups.

```plaintext
POST /groups/:id/service_accounts
```

Supported attributes:

| Attribute  | Type           | Required | Description                                                                   |
|:-----------|:---------------|:---------|:------------------------------------------------------------------------------|
| `id`       | integer/string | yes | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of a top-level group.     |
| `name`     | string         | no  | User account name. If not specified, uses `Service account user`.                  |
| `username` | string         | no  | User account username. If not specified, generates a name prepended with `service_account_`. |

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

Deletes a service account user from a given top-level group.

NOTE:
This endpoint only works on top-level groups.

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

## Create a personal access token for a service account user

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/406781) in GitLab 16.1.

Creates a personal access token for an existing service account user in a given top-level group.

NOTE:
This endpoint only works on top-level groups.

```plaintext
POST /groups/:id/service_accounts/:user_id/personal_access_tokens
```

Parameters:

| Attribute | Type            | Required | Description |
| --------- | --------------- | -------- | ----------- |
| `id`      | integer/string | yes  | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of a top-level group. |
| `user_id` | integer | yes      | ID of service account user.                            |
| `name`    | string  | yes      | Name of personal access token. |
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

## Rotate a personal access token for a service account user

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/406781) in GitLab 16.1.

Rotates a personal access token for an existing service account user in a given top-level group. This creates a new token valid for one week and revokes any existing tokens.

NOTE:
This endpoint only works on top-level groups.

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

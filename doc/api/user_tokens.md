---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: User tokens API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to interact with personal access tokens and impersonation tokens. For more information, see [personal access tokens](../user/profile/personal_access_tokens.md) and [impersonation tokens](rest/authentication.md#impersonation-tokens).

## Create a personal access token for a user

{{< history >}}

- `last_used_ips` in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250307) in GitLab 19.4.
- `granular_scopes` parameter and response attribute [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/630541) in GitLab 19.6.

{{< /history >}}

Creates a personal access token for a specified user. To create a
[fine-grained personal access token](../auth/tokens/fine_grained_access_tokens.md),
use `granular_scopes` instead of `scopes`.

Token values are included with the response, but cannot be retrieved later.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
POST /users/:user_id/personal_access_tokens
```

Supported attributes:

| Attribute    | Type    | Required | Description |
|:-------------|:--------|:---------|:------------|
| `user_id`    | integer | yes      | ID of user account. |
| `name`       | string  | yes      | Name of personal access token. |
| `description`| string  | no       | Description of personal access token. Maximum: 255 characters. |
| `expires_at` | date    | no       | Expiration date of the access token in ISO format (`YYYY-MM-DD`). If undefined and the token requires an expiration date, defaults to the [maximum allowable lifetime limit](../user/profile/personal_access_tokens.md#access-token-expiration). If not required, the token has no expiration date. |
| `scopes`     | array   | Conditional | Array of approved scopes. For a list of possible values, see [access token scopes](../security/tokens/access_token_scopes.md). Required if `granular_scopes` is not provided. Cannot be used with `granular_scopes`. |
| `granular_scopes` | array | Conditional | Fine-grained scopes of the token, one object for each scope. Required if `scopes` is not provided. Cannot be used with `scopes`. |
| `granular_scopes[].access` | string | yes | Resources the scope grants access to. One of `personal_projects`, `all_memberships`, `selected_memberships`, `user`, or `instance`. |
| `granular_scopes[].permissions` | array | yes | Permissions the scope grants. For more information, see [available fine-grained permissions](../auth/tokens/fine_grained_access_tokens.md#available-fine-grained-permissions). |
| `granular_scopes[].group_ids` | integer array | no | IDs of the groups the scope applies to, when `access` is `selected_memberships`. |
| `granular_scopes[].project_ids` | integer array | no | IDs of the projects the scope applies to, when `access` is `selected_memberships`. |

The scopes in `granular_scopes` apply to the user the token is for. With `selected_memberships`,
that user must have access to each group and project you list.

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "name=mytoken" --data "expires_at=2017-04-04" \
  --data "scopes[]=api" \
  --url "https://gitlab.example.com/api/v4/users/42/personal_access_tokens"
```

Example request for a fine-grained personal access token:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"name": "mytoken", "expires_at": "2017-04-04", "granular_scopes": [{"access": "selected_memberships", "permissions": ["read_job"], "project_ids": [6]}]}' \
  --url "https://gitlab.example.com/api/v4/users/42/personal_access_tokens"
```

Example response:

```json
{
    "id": 3,
    "name": "mytoken",
    "revoked": false,
    "created_at": "2020-10-14T11:58:53.526Z",
    "description": "Test Token description",
    "scopes": [
        "api"
    ],
    "user_id": 42,
    "last_used_ips": [],
    "active": true,
    "expires_at": "2020-12-31",
    "token": "<your_new_access_token>"
}
```

> [!note]
> For tokens created with granular scopes, the response also includes a `granular_scopes`
> attribute. For more information, see
> [List all personal access tokens](personal_access_tokens.md#list-all-personal-access-tokens).

## Create a personal access token

{{< history >}}

- `granular_scopes` parameter [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/243428) in GitLab 19.2.
- `last_used_ips` in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250307) in GitLab 19.4.
- `granular_scopes` in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/632314) in GitLab 19.5.

{{< /history >}}

Creates a personal access token for your account. To create a
[fine-grained personal access token](../auth/tokens/fine_grained_access_tokens.md),
use `granular_scopes` instead of `scopes`. For security purposes, a token created with `scopes`:

- Is limited to the [`k8s_proxy` and `self_rotate` scope](../security/tokens/access_token_scopes.md).

Token values are included with the response, but cannot be retrieved later.

Prerequisites:

- You must be authenticated.

```plaintext
POST /user/personal_access_tokens
```

Supported attributes:

| Attribute    | Type   | Required | Description |
|:-------------|:-------|:---------|:------------|
| `name`       | string | yes      | Name of personal access token. |
| `description`| string | no       | Description of personal access token. Maximum: 255 characters. |
| `scopes`     | array  | Conditional | Array of approved scopes. Only accepts `k8s_proxy` and `self_rotate`. Required if `granular_scopes` is not provided. Cannot be used with `granular_scopes`. |
| `expires_at` | date  | no       | Expiration date of the access token in ISO format (`YYYY-MM-DD`). If undefined and the token requires an expiration date, defaults to the [maximum allowable lifetime limit](../user/profile/personal_access_tokens.md#access-token-expiration). If not required, the token has no expiration date. |
| `granular_scopes` | array | Conditional | Fine-grained scopes of the token, one object for each scope. Required if `scopes` is not provided. Cannot be used with `scopes`. |
| `granular_scopes[].access` | string | yes | Resources the scope grants access to. One of `personal_projects`, `all_memberships`, `selected_memberships`, `user`, or `instance`. |
| `granular_scopes[].permissions` | array | yes | Permissions the scope grants. For more information, see [available fine-grained permissions](../auth/tokens/fine_grained_access_tokens.md#available-fine-grained-permissions). |
| `granular_scopes[].group_ids` | integer array | no | IDs of the groups the scope applies to, when `access` is `selected_memberships`. |
| `granular_scopes[].project_ids` | integer array | no | IDs of the projects the scope applies to, when `access` is `selected_memberships`. |

With `selected_memberships`, you must have access to each group and project you list.

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "name=mytoken" --data "scopes[]=k8s_proxy" \
  --url "https://gitlab.example.com/api/v4/user/personal_access_tokens"
```

Example response:

```json
{
    "id": 3,
    "name": "mytoken",
    "revoked": false,
    "created_at": "2020-10-14T11:58:53.526Z",
    "description": "Test Token description",
    "scopes": [
        "k8s_proxy"
    ],
    "user_id": 42,
    "last_used_ips": [],
    "active": true,
    "expires_at": "2020-10-15",
    "token": "<your_new_access_token>"
}
```

> [!note]
> For tokens created with granular scopes, the response also includes a `granular_scopes`
> attribute. For more information, see
> [List all personal access tokens](personal_access_tokens.md#list-all-personal-access-tokens).

## List all impersonation tokens for a user

{{< history >}}

- `last_used_ips` in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/242819) in GitLab 19.2 [with a feature flag](../administration/feature_flags/_index.md) named `expose_last_used_ips_for_access_tokens`. Disabled by default.
- `last_used_ips` in the response [generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/603636) in GitLab 19.4. Feature flag `expose_last_used_ips_for_access_tokens` removed.
- `granular_scopes` in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/632315) in GitLab 19.5.
- `created_after`, `created_before`, `expires_after`, `expires_before`, `last_used_after`, `last_used_before`, `revoked`, `search`, and `sort` attributes [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/260698) in GitLab 19.6.

{{< /history >}}

Lists all impersonation tokens for a specified user.

Use the `page` and `per_page` [pagination parameters](rest/_index.md#offset-based-pagination) to filter the results.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
GET /users/:user_id/impersonation_tokens
```

Supported attributes:

| Attribute          | Type                | Required | Description |
|:-------------------|:--------------------|:---------|:------------|
| `user_id`          | integer             | yes      | ID of user account |
| `created_after`    | datetime (ISO 8601) | no       | If defined, returns tokens created after the specified time. |
| `created_before`   | datetime (ISO 8601) | no       | If defined, returns tokens created before the specified time. |
| `expires_after`    | date (ISO 8601)     | no       | If defined, returns tokens that expire after the specified time. |
| `expires_before`   | date (ISO 8601)     | no       | If defined, returns tokens that expire before the specified time. |
| `last_used_after`  | datetime (ISO 8601) | no       | If defined, returns tokens last used after the specified time. |
| `last_used_before` | datetime (ISO 8601) | no       | If defined, returns tokens last used before the specified time. |
| `revoked`          | boolean             | no       | If `true`, only returns revoked tokens. |
| `search`           | string              | no       | If defined, returns tokens that include the specified value in the name. |
| `sort`             | string              | no       | If defined, sorts the results by the specified value. Possible values: `created_asc`, `created_desc`, `expires_asc`, `expires_desc`, `last_used_asc`, `last_used_desc`, `name_asc`, `name_desc`. |
| `state`            | string              | no       | If defined, returns tokens with the specified state. Possible values: `active`, `inactive`, or `all`. `all` returns tokens in any state. |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/impersonation_tokens"
```

Example response:

```json
[
   {
      "active" : true,
      "user_id" : 2,
      "scopes" : [
         "api"
      ],
      "revoked" : false,
      "name" : "mytoken",
      "description": "Test Token description",
      "id" : 2,
      "created_at" : "2017-03-17T17:18:09.283Z",
      "impersonation" : true,
      "expires_at" : "2017-04-04",
      "last_used_at": "2017-03-24T09:44:21.722Z",
      "last_used_ips": ["192.0.2.10"]
   },
   {
      "active" : false,
      "user_id" : 2,
      "scopes" : [
         "read_user"
      ],
      "revoked" : true,
      "name" : "mytoken2",
      "description": "Test Token description",
      "created_at" : "2017-03-17T17:19:28.697Z",
      "id" : 3,
      "impersonation" : true,
      "expires_at" : "2017-04-14",
      "last_used_at": "2017-03-24T09:44:21.722Z",
      "last_used_ips": ["192.0.2.11"]
   }
]
```

> [!note]
> For impersonation tokens created with granular scopes, the response also includes a
> `granular_scopes` attribute. For more information, see
> [List all personal access tokens](personal_access_tokens.md#list-all-personal-access-tokens).

## Retrieve an impersonation token for a user

{{< history >}}

- `last_used_ips` in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/242819) in GitLab 19.2 [with a feature flag](../administration/feature_flags/_index.md) named `expose_last_used_ips_for_access_tokens`. Disabled by default.
- `last_used_ips` in the response [generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/603636) in GitLab 19.4. Feature flag `expose_last_used_ips_for_access_tokens` removed.
- `granular_scopes` in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/632315) in GitLab 19.5.

{{< /history >}}

Retrieves an impersonation token for a specified user.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
GET /users/:user_id/impersonation_tokens/:impersonation_token_id
```

Supported attributes:

| Attribute                | Type    | Required | Description |
|:-------------------------|:--------|:---------|:------------|
| `user_id`                | integer | yes      | ID of user account |
| `impersonation_token_id` | integer | yes      | ID of impersonation token |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/impersonation_tokens/2"
```

Example response:

```json
{
   "active" : true,
   "user_id" : 2,
   "scopes" : [
      "api"
   ],
   "revoked" : false,
   "name" : "mytoken",
   "description": "Test Token description",
   "id" : 2,
   "created_at" : "2017-03-17T17:18:09.283Z",
   "impersonation" : true,
   "expires_at" : "2017-04-04",
   "last_used_ips": ["192.0.2.10"]
}
```

> [!note]
> For impersonation tokens created with granular scopes, the response also includes a
> `granular_scopes` attribute. For more information, see
> [List all personal access tokens](personal_access_tokens.md#list-all-personal-access-tokens).

## Create an impersonation token

{{< history >}}

- `granular_scopes` parameter [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/243990) in GitLab 19.2.
- `last_used_ips` in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/242819) in GitLab 19.2 [with a feature flag](../administration/feature_flags/_index.md) named `expose_last_used_ips_for_access_tokens`. Disabled by default.
- `last_used_ips` in the response [generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/603636) in GitLab 19.4. Feature flag `expose_last_used_ips_for_access_tokens` removed.
- `granular_scopes` in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/632315) in GitLab 19.5.

{{< /history >}}

Creates an impersonation token for a specified user. These tokens are used to act on behalf of a user and can perform API calls as well as Git read and write actions. These tokens are not visible to the associated user on their profile settings page.
To create a fine-grained impersonation token, use `granular_scopes` instead of `scopes`.

Token values are included with the response, but cannot be retrieved later.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
POST /users/:user_id/impersonation_tokens
```

Supported attributes:

| Attribute    | Type    | Required | Description |
|:-------------|:--------|:---------|:------------|
| `user_id`    | integer | yes      | ID of user account |
| `name`       | string  | yes      | Name of impersonation token |
| `description`| string  | no       | Description of impersonation token |
| `expires_at` | date    | yes      | Expiration date of the impersonation token in ISO format (`YYYY-MM-DD`). If undefined, the date is set to the [maximum allowable lifetime limit](../user/profile/personal_access_tokens.md#access-token-expiration). |
| `scopes`     | array   | Conditional | Array of approved scopes. For a list of possible values, see [access token scopes](../security/tokens/access_token_scopes.md). Required if `granular_scopes` is not provided. Cannot be used with `granular_scopes`. |
| `granular_scopes` | array | Conditional | Fine-grained scopes of the token, one object for each scope. Required if `scopes` is not provided. Cannot be used with `scopes`. |
| `granular_scopes[].access` | string | yes | Resources the scope grants access to. One of `personal_projects`, `all_memberships`, `selected_memberships`, `user`, or `instance`. |
| `granular_scopes[].permissions` | array | yes | Permissions the scope grants. For more information, see [available fine-grained permissions](../auth/tokens/fine_grained_access_tokens.md#available-fine-grained-permissions). |
| `granular_scopes[].group_ids` | integer array | no | IDs of the groups the scope applies to, when `access` is `selected_memberships`. |
| `granular_scopes[].project_ids` | integer array | no | IDs of the projects the scope applies to, when `access` is `selected_memberships`. |

The scopes in `granular_scopes` apply to the user the token is for. With `selected_memberships`,
that user must have access to each group and project you list.

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "name=mytoken" --data "expires_at=2017-04-04" \
  --data "scopes[]=api" \
  --url "https://gitlab.example.com/api/v4/users/42/impersonation_tokens"
```

Example response:

```json
{
   "id" : 2,
   "revoked" : false,
   "user_id" : 2,
   "scopes" : [
      "api"
   ],
   "token" : "<impersonation_token>",
   "active" : true,
   "impersonation" : true,
   "name" : "mytoken",
   "description": "Test Token description",
   "created_at" : "2017-03-17T17:18:09.283Z",
   "expires_at" : "2017-04-04",
   "last_used_ips": []
}
```

> [!note]
> For impersonation tokens created with granular scopes, the response also includes a
> `granular_scopes` attribute. For more information, see
> [List all personal access tokens](personal_access_tokens.md#list-all-personal-access-tokens).

## Revoke an impersonation token

Revokes an impersonation token for a specified user.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
DELETE /users/:user_id/impersonation_tokens/:impersonation_token_id
```

Supported attributes:

| Attribute                | Type    | Required | Description |
|:-------------------------|:--------|:---------|:------------|
| `user_id`                | integer | yes      | ID of user account |
| `impersonation_token_id` | integer | yes      | ID of impersonation token |

Example request:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/impersonation_tokens/1"
```

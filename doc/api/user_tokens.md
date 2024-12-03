---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# User tokens API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

You can manage [personal access tokens](../user/profile/personal_access_tokens.md) and
[impersonation tokens](rest/authentication.md#impersonation-tokens) by using the REST API.

## Create a personal access token

> - The `expires_at` attribute default was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120213) in GitLab 16.0.

Create a new personal access token. Token values are returned once so, make sure you save it because you can't access it
again.

Prerequisites:

- You must be an administrator.

```plaintext
POST /users/:user_id/personal_access_tokens
```

Supported attributes:

| Attribute    | Type    | Required | Description |
|:-------------|:--------|:---------|:------------|
| `user_id`    | integer | yes      | ID of the user. |
| `name`       | string  | yes      | Name of the personal access token. |
| `description`| string  | no       | Description of the personal access token. |
| `expires_at` | date    | no       | Expiration date of the access token in ISO format (`YYYY-MM-DD`). If no date is set, the expiration is set to the [maximum allowable lifetime of an access token](../user/profile/personal_access_tokens.md#access-token-expiration). |
| `scopes`     | array   | yes      | Array of scopes of the personal access token. See [personal access token scopes](../user/profile/personal_access_tokens.md#personal-access-token-scopes) for possible values. |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --data "name=mytoken" --data "expires_at=2017-04-04" \
     --data "scopes[]=api" "https://gitlab.example.com/api/v4/users/42/personal_access_tokens"
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
    "active": true,
    "expires_at": "2020-12-31",
    "token": "<your_new_access_token>"
}
```

## Create a personal access token with limited scopes for your account

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131923) in GitLab 16.5.

Create a new personal access token for your account.

Prerequisites:

- You must be authenticated.

For security purposes, the token:

- Is limited to the [`k8s_proxy` scope](../user/profile/personal_access_tokens.md#personal-access-token-scopes).
  This scope grants permission to perform Kubernetes API calls using the agent for Kubernetes.
- By default, expires at the end of the day it was created on.

Token values are returned once, so make sure you save the token because you cannot access it again.

```plaintext
POST /user/personal_access_tokens
```

Supported attributes:

| Attribute    | Type   | Required | Description |
|:-------------|:-------|:---------|:------------|
| `name`       | string | yes      | Name of the personal access token. |
| `description`| string | no       | Description of the personal access token. |
| `scopes`     | array  | yes      | Array of scopes of the personal access token. Possible values are `k8s_proxy`. |
| `expires_at` | array  | no       | Expiration date of the access token in ISO format (`YYYY-MM-DD`). If no date is set, the expiration is at the end of the current day. The expiration is subject to the [maximum allowable lifetime of an access token](../user/profile/personal_access_tokens.md#access-token-expiration). |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --data "name=mytoken" --data "scopes[]=k8s_proxy" "https://gitlab.example.com/api/v4/user/personal_access_tokens"
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
    "active": true,
    "expires_at": "2020-10-15",
    "token": "<your_new_access_token>"
}
```

## Get all impersonation tokens of a user

Retrieve every impersonation token of a user. Use the [pagination parameters](rest/index.md#offset-based-pagination)
`page` and `per_page` to restrict the list of impersonation tokens.

Prerequisites:

- You must be an administrator.

```plaintext
GET /users/:user_id/impersonation_tokens
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `user_id` | integer | yes      | ID of the user. |
| `state`   | string  | no       | Filter tokens based on state: `all`, `active`, or `inactive`. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/42/impersonation_tokens"
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
      "last_used_at": "2017-03-24T09:44:21.722Z"
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
      "last_used_at": "2017-03-24T09:44:21.722Z"
   }
]
```

## Get an impersonation token of a user

Get a user's impersonation token.

Prerequisites:

- You must be an administrator.

```plaintext
GET /users/:user_id/impersonation_tokens/:impersonation_token_id
```

Supported attributes:

| Attribute                | Type    | Required | Description |
|:-------------------------|:--------|:---------|:------------|
| `user_id`                | integer | yes      | ID of the user. |
| `impersonation_token_id` | integer | yes      | ID of the impersonation token. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/42/impersonation_tokens/2"
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
   "expires_at" : "2017-04-04"
}
```

## Create an impersonation token

Create a new impersonation token. You can only create impersonation tokens to impersonate the user and perform
both API calls and Git reads and writes. The user can't see these tokens in their profile settings page.

Token values are returned once. Make sure you save it because you can't access it again.

Prerequisites:

- You must be an administrator.

```plaintext
POST /users/:user_id/impersonation_tokens
```

Supported attributes:

| Attribute    | Type    | Required | Description |
|:-------------|:--------|:---------|:------------|
| `user_id`    | integer | yes      | ID of the user. |
| `name`       | string  | yes      | Name of the impersonation token. |
| `description`| string  | no       | Description of the personal access token. |
| `expires_at` | date    | yes      | Expiration date of the impersonation token in ISO format (`YYYY-MM-DD`). |
| `scopes`     | array   | yes      | Array of scopes of the impersonation token (`api`, `read_user`). |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --data "name=mytoken" --data "expires_at=2017-04-04" \
     --data "scopes[]=api" "https://gitlab.example.com/api/v4/users/42/impersonation_tokens"
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
   "expires_at" : "2017-04-04"
}
```

## Revoke an impersonation token

Revoke an impersonation token.

Prerequisites:

- You must be an administrator.

```plaintext
DELETE /users/:user_id/impersonation_tokens/:impersonation_token_id
```

Supported attributes:

| Attribute                | Type    | Required | Description |
|:-------------------------|:--------|:---------|:------------|
| `user_id`                | integer | yes      | ID of the user. |
| `impersonation_token_id` | integer | yes      | ID of the impersonation token. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/42/impersonation_tokens/1"
```

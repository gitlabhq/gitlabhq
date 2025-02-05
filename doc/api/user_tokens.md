---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: User tokens API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Use this API to interact with personal access tokens and impersonation tokens. For more information, see [personal access tokens](../user/profile/personal_access_tokens.md) and [impersonation tokens](rest/authentication.md#impersonation-tokens).

## Create a personal access token for a user

> - The `expires_at` attribute default was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120213) in GitLab 16.0.

Creates a personal access token for a given user.

Token values are included with the response, but cannot be retrieved later.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
POST /users/:user_id/personal_access_tokens
```

Supported attributes:

| Attribute    | Type    | Required | Description |
|:-------------|:--------|:---------|:------------|
| `user_id`    | integer | yes      | ID of user account |
| `name`       | string  | yes      | Name of personal access token |
| `description`| string  | no       | Description of personal access token |
| `expires_at` | date    | no       | Expiration date of the access token in ISO format (`YYYY-MM-DD`). If undefined, the date is set to the [maximum allowable lifetime limit](../user/profile/personal_access_tokens.md#access-token-expiration). |
| `scopes`     | array   | yes      | Array of approved scopes. For a list of possible values, see [Personal access token scopes](../user/profile/personal_access_tokens.md#personal-access-token-scopes).  |

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

## Create a personal access token

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131923) in GitLab 16.5.

Creates a personal access token for your account. For security purposes, the token:

- Is limited to the [`k8s_proxy` scope](../user/profile/personal_access_tokens.md#personal-access-token-scopes).
  This scope grants permission to perform Kubernetes API calls using the agent for Kubernetes.
- By default, expires at the end of the day it was created on.

Token values are included with the response, but cannot be retrieved later.

Prerequisites:

- You must be authenticated.

```plaintext
POST /user/personal_access_tokens
```

Supported attributes:

| Attribute    | Type   | Required | Description |
|:-------------|:-------|:---------|:------------|
| `name`       | string | yes      | Name of personal access token |
| `description`| string | no       | Description of personal access token |
| `scopes`     | array  | yes      | Array of approved scopes. Only accepts `k8s_proxy`. |
| `expires_at` | array  | no       | Expiration date of the access token in ISO format (`YYYY-MM-DD`). If undefined, the date is set to the [maximum allowable lifetime limit](../user/profile/personal_access_tokens.md#access-token-expiration). |

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

## List all impersonation tokens for a user

Lists all impersonation tokens for a given user.

Use the `page` and `per_page` [pagination parameters](rest/_index.md#offset-based-pagination) to filter the results.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
GET /users/:user_id/impersonation_tokens
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `user_id` | integer | yes      | ID of user account |
| `state`   | string  | no       | Filter tokens based on state. Possible values: `all`, `active`, or `inactive`. |

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

## Get an impersonation token for a user

Gets an impersonation token for a given user.

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

Creates an impersonation token for a given user. These tokens are used to act on behalf of a user and can perform API calls as well as Git read and write actions. These tokens are not visible to the associated user on their profile settings page.

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
| `scopes`     | array   | yes      | Array of approved scopes. For a list of possible values, see [Personal access token scopes](../user/profile/personal_access_tokens.md#personal-access-token-scopes).  |

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

Revokes an impersonation token for a given user.

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
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/42/impersonation_tokens/1"
```

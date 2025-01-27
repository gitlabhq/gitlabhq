---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Project access tokens API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use this API to interact with project access tokens. For more information, see [Project access tokens](../user/project/settings/project_access_tokens.md).

## List project access tokens

> - `state` attribute [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/462217) in GitLab 17.2.

Get a list of [project access tokens](../user/project/settings/project_access_tokens.md).

In GitLab 17.2 and later, you can use the `state` attribute to limit the response to project access tokens with a specified state.

```plaintext
GET projects/:id/access_tokens
GET projects/:id/access_tokens?state=inactive
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | ID or [URL-encoded path of the project](rest/index.md#namespaced-paths) |
| `state` | string | No | Limit results to tokens with specified state. Valid values are `active` and `inactive`. By default both states are returned. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens"
```

```json
[
   {
      "user_id" : 141,
      "scopes" : [
         "api"
      ],
      "name" : "token",
      "expires_at" : "2021-01-31",
      "id" : 42,
      "active" : true,
      "created_at" : "2021-01-20T22:11:48.151Z",
      "last_used_at" : null,
      "revoked" : false,
      "access_level" : 40
   },
   {
      "user_id" : 141,
      "scopes" : [
         "read_api"
      ],
      "name" : "token-2",
      "expires_at" : "2021-01-31",
      "id" : 43,
      "active" : false,
      "created_at" : "2021-01-21T12:12:38.123Z",
      "revoked" : true,
      "last_used_at" : "2021-02-13T10:34:57.178Z",
      "access_level" : 40
   }
]
```

## Get a project access token

Get a [project access token](../user/project/settings/project_access_tokens.md) by ID.

```plaintext
GET projects/:id/access_tokens/:token_id
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | ID or [URL-encoded path of the project](rest/index.md#namespaced-paths) |
| `token_id` | integer | yes | ID of the project access token |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens/<token_id>"
```

```json
{
   "user_id" : 141,
   "scopes" : [
      "api"
   ],
   "name" : "token",
   "expires_at" : "2021-01-31",
   "id" : 42,
   "active" : true,
   "created_at" : "2021-01-20T22:11:48.151Z",
   "revoked" : false,
   "access_level": 40,
   "last_used_at": "2022-03-15T11:05:42.437Z"
}
```

## Create a project access token

> - The `expires_at` attribute default was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120213) in GitLab 16.0.

Create a [project access token](../user/project/settings/project_access_tokens.md).

When you create a project access token, the maximum role (access level) you set depends on if you have the Owner or Maintainer role for the group. For example, the maximum
role that can be set is:

- Owner (`50`), if you have the Owner role for the project.
- Maintainer (`40`), if you have the Maintainer role on the project.

```plaintext
POST projects/:id/access_tokens
```

| Attribute | Type    | required | Description                                                                                                                           |
|-----------|---------|----------|---------------------------------------------------------------------------------------------------------------------------------------|
| `id` | integer or string | yes | ID or [URL-encoded path of the project](rest/index.md#namespaced-paths)                                                            |
| `name` | string | yes | Name of the project access token                                                                                                               |
| `scopes` | `Array[String]` | yes | [List of scopes](../user/project/settings/project_access_tokens.md#scopes-for-a-project-access-token)                               |
| `access_level` | integer | no | Access level. Valid values are `10` (Guest), `15` (Planner), `20` (Reporter), `30` (Developer), `40` (Maintainer), and `50` (Owner). Defaults to `40`. |
| `expires_at` | date    | yes | Expiration date of the access token in ISO format (`YYYY-MM-DD`). If undefined, the date is set to the [maximum allowable lifetime limit](../user/profile/personal_access_tokens.md#access-token-expiration). |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
--header "Content-Type:application/json" \
--data '{ "name":"test_token", "scopes":["api", "read_repository"], "expires_at":"2021-01-31", "access_level":30 }' \
"https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens"
```

```json
{
   "scopes" : [
      "api",
      "read_repository"
   ],
   "active" : true,
   "name" : "test",
   "revoked" : false,
   "created_at" : "2021-01-21T19:35:37.921Z",
   "user_id" : 166,
   "id" : 58,
   "expires_at" : "2021-01-31",
   "token" : "D4y...Wzr",
   "access_level": 30
}
```

## Rotate a project access token

Rotate a project access token. Revokes the previous token and creates a new token that expires in one week.

You can either:

- Use a project access token ID.
- In GitLab 17.9 and later, pass the project access token to the API in a request header.

### Use a project access token ID

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/403042) in GitLab 16.0

Prerequisites:

- You must have a [personal access token with the `api` scope](../user/profile/personal_access_tokens.md#personal-access-token-scopes).

In GitLab 16.6 and later, you can use the `expires_at` parameter to set a different expiry date. This non-default expiry date can be up to a maximum of one year from the rotation date.

```plaintext
POST /projects/:id/access_tokens/:token_id/rotate
```

| Attribute | Type       | required | Description         |
|-----------|------------|----------|---------------------|
| `id` | integer or string  | yes      | ID or [URL-encoded path of the project](rest/index.md#namespaced-paths) |
| `token_id` | integer | yes | ID of the project access token |
| `expires_at` | date    | no       | Expiration date of the access token in ISO format (`YYYY-MM-DD`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416795) in GitLab 16.6. If undefined, the token expires after one week. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
"https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens/<token_id>/rotate"
```

Example response:

```json
{
    "id": 42,
    "name": "Rotated Token",
    "revoked": false,
    "created_at": "2023-08-01T15:00:00.000Z",
    "description": "Test project access token",
    "scopes": ["api"],
    "user_id": 1337,
    "last_used_at": null,
    "active": true,
    "expires_at": "2023-08-15",
    "access_level": 30,
    "token": "s3cr3t"
}
```

#### Responses

- `200: OK` if the existing token is successfully revoked and the new token is successfully created.
- `400: Bad Request` if not rotated successfully.
- `401: Unauthorized` if either the:
  - User does not have access to the token with the specified ID.
  - Token with the specified ID does not exist.
- `401: Unauthorized` if any of the following conditions are true:
  - You do not have access to the specified token.
  - The specified token does not exist.
  - You're authenticating with a project access token. Use [`/projects/:id/access_tokens/self/rotate`](#use-a-request-header). instead.
- `404: Not Found` if the user is an administrator but the token with the specified ID does not exist.

### Use a request header

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178111) in GitLab 17.9

Requires:

- `api` or `self_rotate` scope.

In GitLab 16.6 and later, you can use the `expires_at` parameter to set a different expiry date. This non-default expiry date is subject to the [maximum allowable lifetime limits](../user/profile/personal_access_tokens.md#access-token-expiration).

```plaintext
POST /projects/:id/access_tokens/self/rotate
```

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_project_access_token>" \
"https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens/self/rotate"
```

Example response:

```json
{
    "id": 42,
    "name": "Rotated Token",
    "revoked": false,
    "created_at": "2025-01-19T15:00:00.000Z",
    "description": "Test project access token",
    "scopes": ["read_api","self_rotate"],
    "user_id": 1337,
    "last_used_at": null,
    "active": true,
    "expires_at": "2025-01-26",
    "access_level": 30,
    "token": "s3cr3t"
}
```

#### Responses

- `200: OK` if the existing project access token is successfully revoked and the new token successfully created.
- `400: Bad Request` if not rotated successfully.
- `401: Unauthorized` if any of the following conditions are true:
  - The token does not exist.
  - The token has expired.
  - The token was revoked.
  - The token is not a project access token associated with the specified project.
- `403: Forbidden` if the token is not allowed to rotate itself.
- `405: Method Not Allowed` if the token is not a project access token.

### Automatic reuse detection

Refer to [automatic reuse detection for personal access tokens](personal_access_tokens.md#automatic-reuse-detection)
for more information.

## Revoke a project access token

Revoke a [project access token](../user/project/settings/project_access_tokens.md).

```plaintext
DELETE projects/:id/access_tokens/:token_id
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | ID or [URL-encoded path of the project](rest/index.md#namespaced-paths) |
| `token_id` | integer | yes | ID of the project access token |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens/<token_id>"
```

### Responses

- `204: No Content` if successfully revoked.
- `400 Bad Request` or `404 Not Found` if not revoked successfully.

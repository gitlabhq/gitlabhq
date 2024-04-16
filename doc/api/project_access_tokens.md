---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Project access tokens API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

You can read more about [project access tokens](../user/project/settings/project_access_tokens.md).

## List project access tokens

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/238991) in GitLab 13.9.

Get a list of [project access tokens](../user/project/settings/project_access_tokens.md).

```plaintext
GET projects/:id/access_tokens
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) |

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
      "revoked" : false,
      "access_level": 40
   }
]
```

## Get a project access token

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/82714) in GitLab 14.10.

Get a [project access token](../user/project/settings/project_access_tokens.md) by ID.

```plaintext
GET projects/:id/access_tokens/:token_id
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) |
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

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/55408) in GitLab 13.10.
> - The `token` attribute was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/55408) in GitLab 13.10.
> - The `expires_at` attribute default was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120213) in GitLab 16.0.

Create a [project access token](../user/project/settings/project_access_tokens.md).

When you create a project access token, the maximum role (access level) you set depends on if you have the Owner or Maintainer role for the group. For example, the maximum
role that can be set is:

- Owner (`50`), if you have the Owner role for the project.
- Maintainer (`40`), if you have the Maintainer role on the project.

In GitLab 14.8 and earlier, project access tokens have a maximum role of Maintainer.

```plaintext
POST projects/:id/access_tokens
```

| Attribute | Type    | required | Description                                                                                                                           |
|-----------|---------|----------|---------------------------------------------------------------------------------------------------------------------------------------|
| `id` | integer or string | yes | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding)                                                            |
| `name` | string | yes | Name of the project access token                                                                                                               |
| `scopes` | `Array[String]` | yes | [List of scopes](../user/project/settings/project_access_tokens.md#scopes-for-a-project-access-token)                               |
| `access_level` | integer | no | Access level. Valid values are `10` (Guest), `20` (Reporter), `30` (Developer), `40` (Maintainer), and `50` (Owner). Defaults to `40`. |
| `expires_at` | date    | yes | Expiration date of the access token in ISO format (`YYYY-MM-DD`). The date cannot be set later than the [maximum allowable lifetime of an access token](../user/profile/personal_access_tokens.md#when-personal-access-tokens-expire). |

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

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/403042) in GitLab 16.0

Prerequisites:

- You must have a [personal access token with the `api` scope](../user/profile/personal_access_tokens.md#personal-access-token-scopes).

Rotate a project access token. Revokes the previous token and creates a new token that expires in one week.

In GitLab 16.6 and later, you can use the `expires_at` parameter to set a different expiry date. This non-default expiry date can be up to a maximum of one year from the rotation date.

```plaintext
POST /projects/:id/access_tokens/:token_id/rotate
```

| Attribute | Type       | required | Description         |
|-----------|------------|----------|---------------------|
| `id` | integer or string  | yes      | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) |
| `token_id` | integer | yes | ID of the project access token |
| `expires_at` | date    | no       | Expiration date of the access token in ISO format (`YYYY-MM-DD`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416795) in GitLab 16.6. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens/<token_id>/rotate"
```

Example response:

```json
{
    "id": 42,
    "name": "Rotated Token",
    "revoked": false,
    "created_at": "2023-08-01T15:00:00.000Z",
    "scopes": ["api"],
    "user_id": 1337,
    "last_used_at": null,
    "active": true,
    "expires_at": "2023-08-15",
    "access_level": 30,
    "token": "s3cr3t"
}
```

### Responses

- `200: OK` if the existing token is successfully revoked and the new token is successfully created.
- `400: Bad Request` if not rotated successfully.
- `401: Unauthorized` if either the:
  - User does not have access to the token with the specified ID.
  - Token with the specified ID does not exist.
- `404: Not Found` if the user is an administrator but the token with the specified ID does not exist.

### Automatic reuse detection

Refer to [automatic reuse detection for personal access tokens](personal_access_tokens.md#automatic-reuse-detection)
for more information.

## Revoke a project access token

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/238991) in GitLab 13.9.

Revoke a [project access token](../user/project/settings/project_access_tokens.md).

```plaintext
DELETE projects/:id/access_tokens/:token_id
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) |
| `token_id` | integer | yes | ID of the project access token |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens/<token_id>"
```

### Responses

- `204: No Content` if successfully revoked.
- `400 Bad Request` or `404 Not Found` if not revoked successfully.

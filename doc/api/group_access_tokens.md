---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Group access tokens API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

You can read more about [group access tokens](../user/group/settings/group_access_tokens.md).

## List group access tokens

> - `state` attribute [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/462217) in GitLab 17.2.

Get a list of [group access tokens](../user/group/settings/group_access_tokens.md).

In GitLab 17.2 and later, you can use the `state` attribute to limit the response to group access tokens with a specified state.

```plaintext
GET /groups/:id/access_tokens
GET /groups/:id/access_tokens?state=inactive
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `state` | string | No | Limit results to tokens with specified state. Valid values are `active` and `inactive`. By default both states are returned. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/<group_id>/access_tokens"
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
      "last_used_at": null,
      "access_level": 40
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
      "last_used_at": "2021-02-13T10:34:57.178Z",
      "access_level": 40
   }
]
```

## Get a group access token

Get a [group access token](../user/group/settings/group_access_tokens.md) by ID.

```plaintext
GET /groups/:id/access_tokens/:token_id
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `token_id` | integer | yes | ID of the group access token |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/<group_id>/access_tokens/<token_id>"
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
   "access_level": 40
}
```

## Create a group access token

> - The `expires_at` attribute default was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120213) in GitLab 16.0.

Create a [group access token](../user/group/settings/group_access_tokens.md). You must have the Owner role for the
group to create group access tokens.

```plaintext
POST /groups/:id/access_tokens
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `name` | String | yes | Name of the group access token  |
| `scopes` | `Array[String]` | yes | [List of scopes](../user/group/settings/group_access_tokens.md#scopes-for-a-group-access-token) |
| `access_level` | Integer | no | Access level. Valid values are `10` (Guest), `20` (Reporter), `30` (Developer), `40` (Maintainer), and `50` (Owner). |
| `expires_at` | Date    | yes | Expiration date of the access token in ISO format (`YYYY-MM-DD`). The date cannot be set later than the [maximum allowable lifetime of an access token](../user/profile/personal_access_tokens.md#when-personal-access-tokens-expire). |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
--header "Content-Type:application/json" \
--data '{ "name":"test_token", "scopes":["api", "read_repository"], "expires_at":"2021-01-31", "access_level": 30 }' \
"https://gitlab.example.com/api/v4/groups/<group_id>/access_tokens"
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

## Rotate a group access token

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/403042) in GitLab 16.0

Prerequisites:

- You must have a [personal access token with the `api` scope](../user/profile/personal_access_tokens.md#personal-access-token-scopes).

Rotate a group access token. Revokes the previous token and creates a new token that expires in one week.

In GitLab 16.6 and later, you can use the `expires_at` parameter to set a different expiry date. This non-default expiry date can be up to a maximum of one year from the rotation date.

```plaintext
POST /groups/:id/access_tokens/:token_id/rotate
```

| Attribute | Type       | required | Description         |
|-----------|------------|----------|---------------------|
| `id` | integer or string  | yes      | ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `token_id` | integer | yes | ID of the access token |
| `expires_at` | date    | no       | Expiration date of the access token in ISO format (`YYYY-MM-DD`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416795) in GitLab 16.6. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/<group_id>/access_tokens/<token_id>/rotate"
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

- `200: OK` if existing token is successfully revoked and the new token is created.
- `400: Bad Request` if not rotated successfully.
- `401: Unauthorized` if either the:
  - User does not have access to the token with the specified ID.
  - Token with the specified ID does not exist.
- `404: Not Found` if the user is an administrator but the token with the specified ID does not exist.

### Automatic reuse detection

Refer to [automatic reuse detection for personal access tokens](personal_access_tokens.md#automatic-reuse-detection)
for more information.

## Revoke a group access token

Revoke a [group access token](../user/group/settings/group_access_tokens.md).

```plaintext
DELETE /groups/:id/access_tokens/:token_id
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `token_id` | integer | yes | ID of the group access token |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/<group_id>/access_tokens/<token_id>"
```

### Responses

- `204: No Content` if successfully revoked.
- `400 Bad Request` or `404 Not Found` if not revoked successfully.

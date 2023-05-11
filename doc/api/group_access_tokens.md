---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Group access tokens API **(FREE)**

You can read more about [group access tokens](../user/group/settings/group_access_tokens.md).

## List group access tokens

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/77236) in GitLab 14.7.

Get a list of [group access tokens](../user/group/settings/group_access_tokens.md).

```plaintext
GET groups/:id/access_tokens
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |

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
      "access_level": 40
   }
]
```

## Get a group access token

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/82714) in GitLab 14.10.

Get a [group access token](../user/group/settings/group_access_tokens.md) by ID.

```plaintext
GET groups/:id/access_tokens/:token_id
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `token_id` | integer or string | yes | ID of the group access token |

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

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/77236) in GitLab 14.7.

Create a [group access token](../user/group/settings/group_access_tokens.md). You must have the Owner role for the
group to create group access tokens.

```plaintext
POST groups/:id/access_tokens
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `name` | String | yes | Name of the group access token  |
| `scopes` | `Array[String]` | yes | [List of scopes](../user/group/settings/group_access_tokens.md#scopes-for-a-group-access-token) |
| `access_level` | Integer | no | Access level. Valid values are `10` (Guest), `20` (Reporter), `30` (Developer), `40` (Maintainer), and `50` (Owner). |
| `expires_at` | Date | no | Token expires at midnight UTC on that date |

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

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/403042) in GitLab 16.0

Rotate a group access token. Revokes the previous token and creates a new token that expires in one week.

```plaintext
POST /groups/:id/access_tokens/:token_id/rotate
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `token_id` | integer or string | yes | ID of the project access token |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/<group_id>/access_tokens/<token_id>/rotate"
```

### Responses

- `200: OK` if existing token is successfully revoked and the new token is created.
- `400: Bad Request` if not rotated successfully.
- `401: Unauthorized` if either the:
  - User does not have access to the token with the specified ID.
  - Token with the specified ID does not exist.
- `404: Not Found` if the user is an administrator but the token with the specified ID does not exist.

## Revoke a group access token

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/77236) in GitLab 14.7.

Revoke a [group access token](../user/group/settings/group_access_tokens.md).

```plaintext
DELETE groups/:id/access_tokens/:token_id
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `token_id` | integer or string | yes | ID of the group access token |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/<group_id>/access_tokens/<token_id>"
```

### Responses

- `204: No Content` if successfully revoked.
- `400 Bad Request` or `404 Not Found` if not revoked successfully.

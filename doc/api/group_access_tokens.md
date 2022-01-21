---
stage: Manage
group: Authentication & Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
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
| `id` | integer or string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |

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

## Create a group access token

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/77236) in GitLab 14.7.

Create a [group access token](../user/group/settings/group_access_tokens.md).

```plaintext
POST groups/:id/access_tokens
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `name` | String | yes | The name of the group access token  |
| `scopes` | `Array[String]` | yes | [List of scopes](../user/group/settings/group_access_tokens.md#scopes-for-a-group-access-token) |
| `access_level` | Integer | no | A valid access level. Default value is 40 (Maintainer). Other allowed values are 10 (Guest), 20 (Reporter), and 30 (Developer). |
| `expires_at` | Date | no | The token expires at midnight UTC on that date |

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

## Revoke a group access token

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/77236) in GitLab 14.7.

Revoke a [group access token](../user/group/settings/group_access_tokens.md).

```plaintext
DELETE groups/:id/access_tokens/:token_id
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `token_id` | integer or string | yes | The ID of the group access token |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/<group_id>/access_tokens/<token_id>"
```

### Responses

- `204: No Content` if successfully revoked.
- `400 Bad Request` or `404 Not Found` if not revoked successfully.

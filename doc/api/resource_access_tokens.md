---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Project access tokens API

You can read more about [project access tokens](../user/project/settings/project_access_tokens.md).

## List project access tokens

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/238991) in GitLab 13.9.

Get a list of project access tokens.

```plaintext
GET projects/:id/access_tokens
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |

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

## Create a project access token

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/55408) in GitLab 13.10.

Create a project access token.

```plaintext
POST projects/:id/access_tokens
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `name` | String | yes | The name of the project access token  |
| `scopes` | `Array[String]` | yes | [List of scopes](../user/project/settings/project_access_tokens.md#limiting-scopes-of-a-project-access-token) |
| `access_level` | Integer | no | A valid access level. Default value is 40 (Maintainer). Other allowed values are 10 (Guest), 20 (Reporter), and 30 (Developer). |
| `expires_at` | Date | no | The token expires at midnight UTC on that date |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
--header "Content-Type:application/json" \
--data '{ "name":"test_token", "scopes":["api", "read_repository"], "expires_at":"2021-01-31", "access_level": 30 }' \
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

## Revoke a project access token

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/238991) in GitLab 13.9.

Revoke a project access token.

```plaintext
DELETE projects/:id/access_tokens/:token_id
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `token_id` | integer or string | yes | The ID of the project access token |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens/<token_id>"
```

### Responses

- `204: No Content` if successfully revoked.
- `400 Bad Request` or `404 Not Found` if not revoked successfully.

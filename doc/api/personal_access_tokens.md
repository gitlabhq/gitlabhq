---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Personal access tokens API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to interact with personal access tokens. For more information, see [Personal access tokens](../user/profile/personal_access_tokens.md).

## List all personal access tokens

{{< history >}}

- `created_after`, `created_before`, `last_used_after`, `last_used_before`, `revoked`, `search` and `state` filters were [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/362248) in GitLab 15.5.

{{< /history >}}

Lists all personal access tokens accessible by the authenticating user. For administrators, returns
a list of all personal access tokens in the instance. For non-administrators, returns a list of the
personal access tokens for the current user.

```plaintext
GET /personal_access_tokens
GET /personal_access_tokens?created_after=2022-01-01T00:00:00
GET /personal_access_tokens?created_before=2022-01-01T00:00:00
GET /personal_access_tokens?last_used_after=2022-01-01T00:00:00
GET /personal_access_tokens?last_used_before=2022-01-01T00:00:00
GET /personal_access_tokens?revoked=true
GET /personal_access_tokens?search=name
GET /personal_access_tokens?state=inactive
GET /personal_access_tokens?user_id=1
```

Supported attributes:

| Attribute          | Type                | Required | Description |
| ------------------ | ------------------- | -------- | ----------- |
| `created_after`    | datetime (ISO 8601) | No       | If defined, returns tokens created after the specified time. |
| `created_before`   | datetime (ISO 8601) | No       | If defined, returns tokens created before the specified time. |
| `expires_after`    | date (ISO 8601)     | No       | If defined, returns tokens that expire after the specified time. |
| `expires_before`   | date (ISO 8601)     | No       | If defined, returns tokens that expire before the specified time. |
| `last_used_after`  | datetime (ISO 8601) | No       | If defined, returns tokens last used after the specified time. |
| `last_used_before` | datetime (ISO 8601) | No       | If defined, returns tokens last used before the specified time. |
| `revoked`          | boolean             | No       | If `true`, only returns revoked tokens. |
| `search`           | string              | No       | If defined, returns tokens that include the specified value in the name. |
| `sort`             | string              | No       | If defined, sorts the results by the specified value. Possible values: `created_asc`, `created_desc`, `expires_asc`, `expires_desc`, `last_used_asc`, `last_used_desc`, `name_asc`, `name_desc`. |
| `state`            | string              | No       | If defined, returns tokens with the specified state. Possible values: `active` and `inactive`. |
| `user_id`          | integer or string   | No       | If defined, returns tokens owned by the specified user. Non-administrators can only filter their own tokens. |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens?user_id=3&created_before=2022-01-01"
```

Example response:

```json
[
    {
        "id": 4,
        "name": "Test Token",
        "revoked": false,
        "created_at": "2020-07-23T14:31:47.729Z",
        "description": "Test Token description",
        "scopes": [
            "api"
        ],
        "user_id": 3,
        "last_used_at": "2021-10-06T17:58:37.550Z",
        "active": true,
        "expires_at": null
    }
]
```

If successful, returns a list of tokens.

Other possible response:

- `401: Unauthorized` if a non-administrator uses the `user_id` attribute to filter for other users.

## Get details on a personal access token

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/362239) in GitLab 15.1.
- `404` HTTP status code [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93650) in GitLab 15.3.

{{< /history >}}

Gets details on a specified personal access token. Administrators can get details on any token.
Non-administrators can only get details on own tokens.

```plaintext
GET /personal_access_tokens/:id
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | ID of a personal access token or the keyword `self`. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/<id>"
```

If successful, returns details on the token.

Other possible responses:

- `401: Unauthorized` if either:
  - The token does not exist.
  - You do not have access to the specified token.
- `404: Not Found` if the user is an administrator but the token does not exist.

### Self-inform

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/373999) in GitLab 15.5

{{< /history >}}

Instead of getting details on a specific personal access token, you can also return details on
the personal access token you used to authenticate the request. To return these details, you must
use the `self` keyword in the request URL.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/self"
```

## Create a personal access token

{{< details >}}

- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can create personal access tokens with the user tokens API. For more information, see the following endpoints:

- [Create a personal access token](user_tokens.md#create-a-personal-access-token)
- [Create a personal access token for a user](user_tokens.md#create-a-personal-access-token-for-a-user)

## Rotate a personal access token

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/403042) in GitLab 16.0
- `expires_at` attribute [added](https://gitlab.com/gitlab-org/gitlab/-/issues/416795) in GitLab 16.6.

{{< /history >}}

Rotates a specified personal access token. This revokes the previous token and creates a new token
that expires after one week. Administrators can revoke tokens for any user. Non-administrators can
only revoke their own tokens.

```plaintext
POST /personal_access_tokens/:id/rotate
```

| Attribute | Type      | Required | Description         |
|-----------|-----------|----------|---------------------|
| `id` | integer or string | yes      | ID of a personal access token or the keyword `self`. |
| `expires_at` | date   | no       | Expiration date of the access token in ISO format (`YYYY-MM-DD`). The date must be one year or less from the rotation date. If undefined, the token expires after one week. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/<personal_access_token_id>/rotate"
```

Example response:

```json
{
    "id": 42,
    "name": "Rotated Token",
    "revoked": false,
    "created_at": "2023-08-01T15:00:00.000Z",
    "description": "Test Token description",
    "scopes": ["api"],
    "user_id": 1337,
    "last_used_at": null,
    "active": true,
    "expires_at": "2023-08-15",
    "token": "s3cr3t"
}
```

If successful, returns `200: OK`.

Other possible responses:

- `400: Bad Request` if not rotated successfully.
- `401: Unauthorized` if any of the following conditions are true:
  - The token does not exist.
  - The token has expired.
  - The token was revoked.
  - You do not have access to the specified token.
- `403: Forbidden` if the token is not allowed to rotate itself.
- `404: Not Found` if the user is an administrator but the token does not exist.
- `405: Method Not Allowed` if the token is not a personal access token.

### Self-rotate

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/426779) in GitLab 16.10

{{< /history >}}

Instead of rotating a specific personal access token, you can also rotate the same personal access
token you used to authenticate the request. To self-rotate a personal access token, you must:

- Rotate a personal access token with the [`api` or `self_rotate` scope](../user/profile/personal_access_tokens.md#personal-access-token-scopes).
- Use the `self` keyword in the request URL.

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/self/rotate"
```

### Automatic reuse detection

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/395352) in GitLab 16.3

{{< /history >}}

When you rotate or revoke a token, GitLab automatically tracks the relationship between the old and
new tokens. Each time a new token is generated, a connection is made to the previous token. These
connected tokens form a token family.

If you attempt to use the API to rotate an access token that was already revoked, any active tokens from the same
token family are revoked.

This feature helps secure GitLab if an old token is ever leaked or stolen. By tracking token
relationships and automatically revoking access when old tokens are used, attackers cannot exploit
compromised tokens.

## Revoke a personal access token

Revokes a specified personal access token. Administrators can revoke tokens for any user.
Non-administrators can only revoke their own tokens.

```plaintext
DELETE /personal_access_tokens/:id
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | ID of a personal access token or the keyword `self`. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/<personal_access_token_id>"
```

If successful, returns `204: No Content`.

Other possible responses:

- `400: Bad Request` if not revoked successfully.
- `401: Unauthorized` if the access token is invalid.
- `403: Forbidden` if the access token does not have the required permissions.

### Self-revoke

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/350240) in GitLab 15.0. Limited to tokens with `api` scope.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/369103) in GitLab 15.4, any token can use this endpoint.

{{< /history >}}

Instead of revoking a specific personal access token, you can also revoke the same personal access
token you used to authenticate the request. To self-revoke a personal access token, you must use
the `self` keyword in the request URL.

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/self"
```

## List all token associations

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/466046) in GitLab 17.4.

{{< /history >}}

Lists all groups and projects accessible by the personal access token used to authenticate the request. Generally, this includes any groups or projects that the user is a member of.

```plaintext
GET /personal_access_tokens/self/associations
GET /personal_access_tokens/self/associations?page=2
GET /personal_access_tokens/self/associations?min_access_level=40
```

Supported attributes:

| Attribute           | Type     | Required | Description                                                              |
|---------------------|----------|----------|--------------------------------------------------------------------------|
| `min_access_level`  | integer  | No       | Limit by current user minimal [role (`access_level`)](members.md#roles). |
| `page`              | integer  | No       | Page to retrieve. Defaults to `1`.                                       |
| `per_page`          | integer  | No       | Number of records to return per page. Defaults to `20`.                  |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/self/associations"
```

Example response:

```json
{
    "groups": [
        {
        "id": 1,
        "web_url": "http://gitlab.example.com/groups/test",
        "name": "Test",
        "parent_id": null,
        "organization_id": 1,
        "access_levels": 20,
        "visibility": "public"
        },
        {
        "id": 3,
        "web_url": "http://gitlab.example.com/groups/test/test_private",
        "name": "Test Private",
        "parent_id": 1,
        "organization_id": 1,
        "access_levels": 50,
        "visibility": "test_private"
        }
    ],
    "projects": [
        {
            "id": 1337,
            "description": "Leet.",
            "name": "Test Project",
            "name_with_namespace": "Test / Test Project",
            "path": "test-project",
            "path_with_namespace": "Test/test-project",
            "created_at": "2024-07-02T13:37:00.123Z",
            "access_levels": {
                "project_access_level": null,
                "group_access_level": 20
            },
            "visibility": "private",
            "web_url": "http://gitlab.example.com/test/test_project",
            "namespace": {
                "id": 1,
                "name": "Test",
                "path": "Test",
                "kind": "group",
                "full_path": "Test",
                "parent_id": null,
                "avatar_url": null,
                "web_url": "http://gitlab.example.com/groups/test"
            }
        }
    ]
}
```

## Related topics

- [Token troubleshooting](../security/tokens/token_troubleshooting.md)

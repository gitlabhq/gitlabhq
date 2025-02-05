---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Personal access tokens API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use this API to interact with personal access tokens. For more information, see [Personal access tokens](../user/profile/personal_access_tokens.md).

## List personal access tokens

> - `created_after`, `created_before`, `last_used_after`, `last_used_before`, `revoked`, `search` and `state` filters were [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/362248) in GitLab 15.5.

Get all personal access tokens the authenticated user has access to. By default, returns an unfiltered list of:

- Only personal access tokens created by the current user to a non-administrator.
- All personal access tokens to an administrator.

Administrators:

- Can use the `user_id` parameter to filter by a user.
- Can use other filters on all personal access tokens (GitLab 15.5 and later).

Non-administrators:

- Cannot use the `user_id` parameter to filter on any user except themselves, otherwise they receive a `401 Unauthorized` response.
- Can only filter on their own personal access tokens (GitLab 15.5 and later).

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

| Attribute           | Type           | Required | Description         |
|---------------------|----------------|----------|---------------------|
| `created_after`     | datetime (ISO 8601) | No | Limit results to PATs created after specified time. |
| `created_before`    | datetime (ISO 8601) | No | Limit results to PATs created before specified time. |
| `last_used_after`   | datetime (ISO 8601) | No | Limit results to PATs last used after specified time. |
| `last_used_before`  | datetime (ISO 8601) | No | Limit results to PATs last used before specified time. |
| `revoked`           | boolean             | No | Limit results to PATs with specified revoked state. Valid values are `true` and `false`. |
| `search`            | string              | No | Limit results to PATs with name containing search string. |
| `state`             | string              | No | Limit results to PATs with specified state. Valid values are `active` and `inactive`. |
| `user_id`           | integer or string   | No | Limit results to PATs owned by specified user. |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens"
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
        "user_id": 24,
        "last_used_at": "2021-10-06T17:58:37.550Z",
        "active": true,
        "expires_at": null
    }
]
```

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens?user_id=3"
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

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens?revoked=true"
```

Example response:

```json
[
    {
        "id": 41,
        "name": "Revoked Test Token",
        "revoked": true,
        "created_at": "2022-01-01T14:31:47.729Z",
        "description": "Test Token description",
        "scopes": [
            "api"
        ],
        "user_id": 8,
        "last_used_at": "2022-05-18T17:58:37.550Z",
        "active": false,
        "expires_at": null
    }
]
```

You can filter by merged attributes with:

```plaintext
GET /personal_access_tokens?revoked=true&created_before=2022-01-01
```

## Get single personal access token

Get a personal access token by either:

- Using the ID of the personal access token.
- Passing it to the API in a header.

### Using a personal access token ID

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/362239) in GitLab 15.1.

Get a single personal access token by its ID. Users can get their own tokens.
Administrators can get any token.

```plaintext
GET /personal_access_tokens/:id
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer/string | yes | ID of personal access token |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/<id>"
```

#### Responses

> - `404` HTTP status code [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93650) in GitLab 15.3.

- `401: Unauthorized` if either:
  - The user doesn't have access to the token with the specified ID.
  - The token with the specified ID doesn't exist.
- `404: Not Found` if the user is an administrator but the token with the specified ID doesn't exist.

### Using a request header

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/373999) in GitLab 15.5

Get a single personal access token and information about that token by passing the token in a header.

```plaintext
GET /personal_access_tokens/self
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/self"
```

Example response:

```json
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
```

## Rotate a personal access token

Rotate a personal access token. Revokes the previous token and creates a new token that expires in one week.

You can either:

- Use the personal access token ID.
- In GitLab 16.10 and later, pass the personal access token to the API in a request header.

### Use a personal access token ID

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/403042) in GitLab 16.0

In GitLab 16.6 and later, you can use the `expires_at` parameter to set a different expiry date. This non-default expiry date is subject to the [maximum allowable lifetime limits](../user/profile/personal_access_tokens.md#access-token-expiration).

```plaintext
POST /personal_access_tokens/:id/rotate
```

| Attribute | Type      | Required | Description         |
|-----------|-----------|----------|---------------------|
| `id` | integer/string | yes      | ID of personal access token |
| `expires_at` | date   | no       | Expiration date of the access token in ISO format (`YYYY-MM-DD`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416795) in GitLab 16.6. If undefined, the token expires after one week. |

NOTE:
Non-administrators can rotate their own tokens. Administrators can rotate tokens of any user.

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

#### Responses

- `200: OK` if the existing token is successfully revoked and the new token successfully created.
- `400: Bad Request` if not rotated successfully.
- `401: Unauthorized` if either the:
  - User does not have access to the token with the specified ID.
  - Token with the specified ID does not exist.
- `404: Not Found` if the user is an administrator but the token with the specified ID does not exist.

### Use a request header

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/426779) in GitLab 16.10

Requires:

- `api` or `self_rotate` scope.

In GitLab 16.6 and later, you can use the `expires_at` parameter to set a different expiry date. This non-default expiry date is subject to the [maximum allowable lifetime limits](../user/profile/personal_access_tokens.md#access-token-expiration).

```plaintext
POST /personal_access_tokens/self/rotate
```

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/self/rotate"
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
    "expires_at": "2023-08-08",
    "token": "s3cr3t"
}
```

#### Responses

- `200: OK` if the existing token is successfully revoked and the new token successfully created.
- `400: Bad Request` if not rotated successfully.
- `401: Unauthorized` if either:
  - The token does not exist.
  - The token has expired.
  - The token has been revoked.
- `403: Forbidden` if the token is not allowed to rotate itself.
- `405: Method Not Allowed` if the token is not a personal access token.

### Automatic reuse detection

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/395352) in GitLab 16.3

For each rotated token, the previous and now revoked token is referenced. This
chain of references defines a token family. In a token family, only the latest
token is active, and all other tokens in that family are revoked.

When a revoked token from a token family is used in an authentication attempt
for the token rotation endpoint, that attempt fails and the active token from
the token family gets revoked.
This mechanism helps to prevent compromise when a personal access token is
leaked.

Automatic reuse detection is enabled for token rotation API requests.

## Revoke a personal access token

Revoke a personal access token by either:

- Using the ID of the personal access token.
- Passing it to the API in a header.

### Using a personal access token ID

Revoke a personal access token using its ID.

```plaintext
DELETE /personal_access_tokens/:id
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer/string | yes | ID of personal access token |

NOTE:
Non-administrators can revoke their own tokens. Administrators can revoke tokens of any user.

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/<personal_access_token_id>"
```

#### Responses

- `204: No Content` if successfully revoked.
- `400: Bad Request` if not revoked successfully.
- `401: Unauthorized` if the access token is invalid.
- `403: Forbidden` if the access token does not have the required permissions.

### Using a request header

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/350240) in GitLab 15.0. Limited to tokens with `api` scope.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/369103) in GitLab 15.4, any token can use this endpoint.

Revokes a personal access token that is passed in using a request header. Requires:

- `api` scope in GitLab 15.0 to GitLab 15.3.
- Any scope in GitLab 15.4 and later.

```plaintext
DELETE /personal_access_tokens/self
```

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/self"
```

#### Responses

- `204: No Content` if successfully revoked.
- `400: Bad Request` if not revoked successfully.
- `401: Unauthorized` if the access token is invalid.

## List token associations

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/466046) in GitLab 17.4.

Returns an unfiltered list of all groups, subgroups, and projects the current authenticated user can access.

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

## Create a personal access token (administrator only)

See the [User tokens API](user_tokens.md#create-a-personal-access-token) for information on creating a personal access
token.

## Create a personal access token with limited scopes for the currently authenticated user

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

See the [User tokens API](user_tokens.md#create-a-personal-access-token) for
information on creating a personal access token for the currently authenticated user.

## Troubleshooting access tokens

To troubleshoot access token issues, see the [token troubleshooting guide](../security/tokens/token_troubleshooting.md).

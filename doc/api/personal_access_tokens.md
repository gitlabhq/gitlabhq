---
stage: Govern
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Personal access tokens API **(FREE)**

You can read more about [personal access tokens](../user/profile/personal_access_tokens.md#personal-access-tokens).

## List personal access tokens

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/227264) in GitLab 13.3.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/270200) from GitLab Ultimate to GitLab Free in 13.6.
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
| `created_after`     | datetime (ISO 8601) | **{dotted-circle}** No | Limit results to PATs created after specified time. |
| `created_before`    | datetime (ISO 8601) | **{dotted-circle}** No | Limit results to PATs created before specified time. |
| `last_used_after`   | datetime (ISO 8601) | **{dotted-circle}** No | Limit results to PATs last used after specified time. |
| `last_used_before`  | datetime (ISO 8601) | **{dotted-circle}** No | Limit results to PATs last used before specified time. |
| `revoked`           | boolean             | **{dotted-circle}** No | Limit results to PATs with specified revoked state. Valid values are `true` and `false`. |
| `search`            | string              | **{dotted-circle}** No | Limit results to PATs with name containing search string. |
| `state`             | string              | **{dotted-circle}** No | Limit results to PATs with specified state. Valid values are `active` and `inactive`. |
| `user_id`           | integer or string   | **{dotted-circle}** No | Limit results to PATs owned by specified user. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/personal_access_tokens"
```

Example response:

```json
[
    {
        "id": 4,
        "name": "Test Token",
        "revoked": false,
        "created_at": "2020-07-23T14:31:47.729Z",
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
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/personal_access_tokens?user_id=3"
```

Example response:

```json
[
    {
        "id": 4,
        "name": "Test Token",
        "revoked": false,
        "created_at": "2020-07-23T14:31:47.729Z",
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
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/personal_access_tokens?revoked=true"
```

Example response:

```json
[
    {
        "id": 41,
        "name": "Revoked Test Token",
        "revoked": true,
        "created_at": "2022-01-01T14:31:47.729Z",
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

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/362239) in GitLab 15.1.

Get a single personal access token by its ID. Users can get their own tokens.
Administrators can get any token.

```plaintext
GET /personal_access_tokens/:id
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer/string | yes | ID of personal access token |

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/personal_access_tokens/<id>"
```

#### Responses

> `404` HTTP status code [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93650) in GitLab 15.3.

- `401: Unauthorized` if either:
  - The user doesn't have access to the token with the specified ID.
  - The token with the specified ID doesn't exist.
- `404: Not Found` if the user is an administrator but the token with the specified ID doesn't exist.

### Using a request header

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/373999) in GitLab 15.5

Get a single personal access token and information about that token by passing the token in a header.

```plaintext
GET /personal_access_tokens/self
```

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/personal_access_tokens/self"
```

Example response:

```json
{
    "id": 4,
    "name": "Test Token",
    "revoked": false,
    "created_at": "2020-07-23T14:31:47.729Z",
    "scopes": [
        "api"
    ],
    "user_id": 3,
    "last_used_at": "2021-10-06T17:58:37.550Z",
    "active": true,
    "expires_at": null
}
```

## Revoke a personal access token

Revoke a personal access token by either:

- Using the ID of the personal access token.
- Passing it to the API in a header.

### Using a personal access token ID

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/216004) in GitLab 13.3.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/270200) from GitLab Ultimate to GitLab Free in 13.6.

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
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/personal_access_tokens/<personal_access_token_id>"
```

#### Responses

- `204: No Content` if successfully revoked.
- `400: Bad Request` if not revoked successfully.

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
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/personal_access_tokens/self"
```

#### Responses

- `204: No Content` if successfully revoked.
- `400: Bad Request` if not revoked successfully.

## Create a personal access token (administrator only)

See the [Users API documentation](users.md#create-a-personal-access-token) for information on creating a personal access token.

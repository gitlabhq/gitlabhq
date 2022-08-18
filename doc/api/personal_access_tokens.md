---
stage: Manage
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Personal access tokens API **(FREE)**

You can read more about [personal access tokens](../user/profile/personal_access_tokens.md#personal-access-tokens).

## List personal access tokens

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/227264) in GitLab 13.3.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/270200) from GitLab Ultimate to GitLab Free in 13.6.

Get a list of personal access tokens.

```plaintext
GET /personal_access_tokens
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `user_id` | integer/string | no | The ID of the user to filter by |

NOTE:
Administrators can use the `user_id` parameter to filter by a user. Non-administrators cannot filter by any user except themselves. Attempting to do so will result in a `401 Unauthorized` response.

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/personal_access_tokens"
```

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

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/personal_access_tokens?user_id=3"
```

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

## Get single personal access token by ID

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/362239) in GitLab 15.1.

Get a single personal access token by its ID. Users can get their own tokens.
Administrators can get any token.

```plaintext
GET /personal_access_tokens/:id
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer/string | yes | ID of personal access token |

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/personal_access_tokens/<id>"
```

### Responses

> `404` HTTP status code [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93650) in GitLab 15.3.

- `401: Unauthorized` if either:
  - The user doesn't have access to the token with the specified ID.
  - The token with the specified ID doesn't exist.
- `404: Not Found` if the user is an administrator but the token with the specified ID doesn't exist.

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

| Attribute | Type    | required | Description         |
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

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/350240) in GitLab 15.0.

Revokes a personal access token that is passed in using a request header.

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

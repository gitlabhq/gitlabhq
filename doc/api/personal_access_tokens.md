---
stage: Manage
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Personal access tokens API

You can read more about [personal access tokens](../user/profile/personal_access_tokens.md#personal-access-tokens).

## List personal access tokens

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/227264) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 13.3.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/270200) to [GitLab Free](https://about.gitlab.com/pricing/) in 13.6.

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
        "active": true,
        "user_id": 24,
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
        "active": true,
        "user_id": 3,
        "expires_at": null
    }
]
```

## Revoke a personal access token

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/216004) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 13.3.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/270200) to [GitLab Free](https://about.gitlab.com/pricing/) in 13.6.

Revoke a personal access token.

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

### Responses

- `204: No Content` if successfully revoked.
- `400 Bad Request` if not revoked successfully.

## Create a personal access token (admin only)

See the [Users API documentation](users.md#create-a-personal-access-token) for information on creating a personal access token.

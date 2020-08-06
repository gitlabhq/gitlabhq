# Personal access tokens API **(ULTIMATE)**

You can read more about [personal access tokens](../user/profile/personal_access_tokens.md#personal-access-tokens).

## List personal access tokens

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/22726) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 13.3.

Get a list of personal access tokens.

```plaintext
GET /personal_access_tokens
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `user_id` | integer/string | no | The ID of the user to filter by |

NOTE: **Note:**
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

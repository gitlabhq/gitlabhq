# Personal Access Token

## List

This function takes pagination parameters `page` and `per_page` to restrict the list of personal access tokens.

```
GET /personal_access_tokens
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `state`   | string | no | filter tokens based on state (all, active, inactive) |

Example response:
```json
[
  {
    "id": 1,
    "name": "mytoken",
    "revoked": false,
    "expires_at": "2017-01-04",
    "scopes": ["api"],
    "active": true
  }
]
```

## Show

```
GET /personal_access_tokens/:personal_access_token_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `personal_access_token_id` | integer | yes | The ID of the personal access token |

## Create

```
POST /personal_access_tokens
```

It responds with the new personal access token for the current user.

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `name` | string | yes | The name of the personal access token |
| `expires_at` | date | no | The expiration date of the personal access token |
| `scopes` | array | no | The array of scopes of the personal access token |

## Revoke

```
DELETE /personal_access_tokens/:personal_access_token_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `personal_access_token_id` | integer | yes | The ID of the personal access token |

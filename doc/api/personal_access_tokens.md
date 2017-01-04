# Personal Access Token

## List

```
GET /personal_access_tokens
```

An example:
```json
[
  {
    "id": 1,
    "name": "mytoken",
    "revoked": false,
    "expires_at": "2017-01-04",
    "scopes": ['api'],
    "active": true
  }
]
```

In addition, you can filter users based on state: `all`, `active` and `inactive`

```
GET /personal_access_tokens?state=all
```

```
GET /personal_access_tokens?state=active
```

```
GET /personal_access_tokens?state=inactive
```

## Create

```
POST /personal_access_tokens
```

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

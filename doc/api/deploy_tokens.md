# Deploy Tokens API

## List all deploy tokens

Get a list of all deploy tokens across the GitLab instance. This endpoint requires admin access.

```plaintext
GET /deploy_tokens
```

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/deploy_tokens"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "MyToken",
    "username": "gitlab+deploy-token-1",
    "expires_at": "2020-02-14T00:00:00.000Z",
    "scopes": [
      "read_repository",
      "read_registry"
    ]
  }
]
```

## Project deploy tokens

Project deploy token API endpoints require project maintainer access or higher.

### List project deploy tokens

Get a list of a project's deploy tokens.

```plaintext
GET /projects/:id/deploy_tokens
```

Parameters:

| Attribute      | Type           | Required | Description                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | integer/string | yes      | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding). |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/deploy_tokens"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "MyToken",
    "username": "gitlab+deploy-token-1",
    "expires_at": "2020-02-14T00:00:00.000Z",
    "scopes": [
      "read_repository",
      "read_registry"
    ]
  }
]
```

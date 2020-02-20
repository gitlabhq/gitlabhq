# Deploy Tokens API

## List all deploy tokens

Get a list of all deploy tokens across all projects of the GitLab instance.

>**Note:**
> This endpoint requires admin access.

```
GET /deploy_tokens
```

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
    "token": "jMRvtPNxrn3crTAGukpZ",
    "scopes": [
      "read_repository",
      "read_registry"
    ]
  }
]
```

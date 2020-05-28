# Import API

## Import repository from GitHub

Import your projects from GitHub to GitLab via the API.

```plaintext
POST /import/github
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `personal_access_token`       | string | yes      | GitHub personal access token |
| `repo_id`   | integer | yes      | GitHub repository ID     |
| `new_name`   | string | no      | New repository name     |
| `target_namespace`   | string | yes      | Namespace to import repository into     |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --data "personal_access_token=abc123&repo_id=12345&target_namespace=root" "https://gitlab.example.com/api/v4/import/github"
```

Example response:

```json
{
    "id": 27,
    "name": "my-repo",
    "full_path": "/root/my-repo",
    "full_name": "Administrator / my-repo"
}
```

---
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

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
| `target_namespace`   | string | yes      | Namespace to import repository into. Supports subgroups like `/namespace/subgroup`.     |
| `github_hostname`   | string  | no  | Custom GitHub Enterprise hostname. Do not set for GitHub.com. |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/github" \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data '{
    "personal_access_token": "aBc123abC12aBc123abC12abC123+_A/c123",
    "repo_id": "12345",
    "target_namespace": "group/subgroup",
    "new_name": "NEW-NAME",
    "github_hostname": "https://github.example.com"
}'
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

## Import repository from Bitbucket Server

Import your projects from Bitbucket Server to GitLab via the API.

NOTE:
The Bitbucket Project Key is only used for finding the repository in Bitbucket.
You must specify a `target_namespace` if you want to import the repository to a GitLab group.
If you do not specify `target_namespace`, the project imports to your personal user namespace.

```plaintext
POST /import/bitbucket_server
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `bitbucket_server_url` | string | yes | Bitbucket Server URL |
| `bitbucket_server_username` | string | yes | Bitbucket Server Username |
| `personal_access_token` | string | yes | Bitbucket Server personal access token/password |
| `bitbucket_server_project` | string | yes | Bitbucket Project Key |
| `bitbucket_server_repo` | string | yes | Bitbucket Repository Name |
| `new_name` | string | no | New repository name |
| `target_namespace` | string | no | Namespace to import repository into. Supports subgroups like `/namespace/subgroup` |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/bitbucket_server" \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data '{
    "bitbucket_server_url": "http://bitbucket.example.com",
    "bitbucket_server_username": "root",
    "personal_access_token": "Nzk4MDcxODY4MDAyOiP8y410zF3tGAyLnHRv/E0+3xYs",
    "bitbucket_server_project": "NEW",
    "bitbucket_server_repo": "my-repo"
}'
```

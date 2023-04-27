---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Import API **(FREE)**

Use the Import API to import repositories from GitHub or Bitbucket Server.

## Prerequisites

For information on prerequisites for using the Import API, see:

- [Prerequisites for GitHub importer](../user/project/import/github.md#prerequisites).
- [Prerequisites for Bitbucket Server importer](../user/project/import/bitbucket_server.md#import-your-bitbucket-repositories).

## Import repository from GitHub

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/381902) in GitLab 15.8, GitLab no longer automatically creates namespaces or groups if the namespace or group name specified in `target_namespace` doesn't exist. GitLab also no longer falls back to using the user's personal namespace if the namespace or group name is taken or `target_namespace` is blank.

Import your projects from GitHub to GitLab using the API.

The namespace set in `target_namespace` must exist. The namespace can be your user namespace or an existing group that
you have at least the Maintainer role for. Using the Developer role for this purpose was
[deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/387891) in GitLab 15.8 and will be removed in GitLab 16.0.

```plaintext
POST /import/github
```

| Attribute               | Type    | Required | Description                                                                         |
|-------------------------|---------|----------|-------------------------------------------------------------------------------------|
| `personal_access_token` | string  | yes      | GitHub personal access token                                                        |
| `repo_id`               | integer | yes      | GitHub repository ID                                                                |
| `new_name`              | string  | no       | New repository name                                                                 |
| `target_namespace`      | string  | yes      | Namespace to import repository into. Supports subgroups like `/namespace/subgroup`. In GitLab 15.8 and later, must not be blank |
| `github_hostname`       | string  | no  | Custom GitHub Enterprise hostname. Do not set for GitHub.com.                       |
| `optional_stages`       | object  | no  | [Additional items to import](../user/project/import/github.md#select-additional-items-to-import). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/373705) in GitLab 15.5 |

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
    "github_hostname": "https://github.example.com",
    "optional_stages": {
      "single_endpoint_issue_events_import": true,
      "single_endpoint_notes_import": true,
      "attachments_import": true
    }
}'
```

The following keys are available for `optional_stages`:

- `single_endpoint_issue_events_import`, for issue and pull request events import.
- `single_endpoint_notes_import`, for an alternative and more thorough comments import.
- `attachments_import`, for Markdown attachments import.

For more information, see [Select additional items to import](../user/project/import/github.md#select-additional-items-to-import).

Example response:

```json
{
    "id": 27,
    "name": "my-repo",
    "full_path": "/root/my-repo",
    "full_name": "Administrator / my-repo"
}
```

### Import a public project through the API using a group access token

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/362683) in GitLab 15.7, projects are not imported into a [bot user's](../user/group/settings/group_access_tokens.md#bot-users-for-groups) namespace in any circumstances. Projects imported into a bot user's namespace could not be deleted by users with valid tokens, which represented a security risk.

When you import a project from GitHub to GitLab through the API using a group access
token:

- The GitLab project inherits the original project's visibility settings. As a result, the project is publicly accessible if the original project is public.
- If the `path` or `target_namespace` does not exist, the project import fails.

### Cancel GitHub project import

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/364783) in GitLab 15.5.

Cancel an in-progress GitHub project import using the API.

```plaintext
POST /import/github/cancel
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `project_id`   | integer | yes      | GitLab project ID     |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/github/cancel" \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data '{
    "project_id": 12345
}'
```

Example response:

```json
{
    "id": 160,
    "name": "my-repo",
    "full_path": "/root/my-repo",
    "full_name": "Administrator / my-repo",
    "import_source": "source/source-repo",
    "import_status": "canceled",
    "human_import_status_name": "canceled",
    "provider_link": "/source/source-repo"
}
```

Returns the following status codes:

- `200 OK`: the project import is being canceled.
- `400 Bad Request`: the project import cannot be canceled.
- `404 Not Found`: the project associated with `project_id` does not exist.

### Import GitHub gists into GitLab snippets

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/371099) in GitLab 15.8 [with a flag](../administration/feature_flags.md) named `github_import_gists`. Disabled by default. Enabled on GitLab.com.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/386579) in GitLab 15.10.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/386579) in GitLab 15.11. Feature flag `github_import_gists` removed.

You can use the GitLab API to import personal GitHub gists (with up to 10 files) into personal GitLab snippets.
GitHub gists with more than 10 files are skipped. You should manually migrate these GitHub gists.

If any gists couldn't be imported, an email is sent with a list of gists that were not imported.

```plaintext
POST /import/github/gists
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `personal_access_token`   | string | yes      | GitHub personal access token     |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/github/gists" \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_gitlab_access_token>" \
  --data '{
    "personal_access_token": "<your_github_personal_access_token>"
}'
```

Returns the following status codes:

- `202 Accepted`: the gists import is being started.
- `401 Unauthorized`: user's GitHub personal access token is invalid.
- `422 Unprocessable Entity`: the gists import is already in progress.
- `429 Too Many Requests`: the user has exceeded GitHub's rate limit.

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

## Automate group and project import **(PREMIUM)**

For information on automating user, group, and project import API calls, see
[Automate group and project import](../user/project/import/index.md#automate-group-and-project-import).

## Related topics

- [Group migration by direct transfer API](bulk_imports.md).
- [Group import and export API](group_import_export.md).
- [Project import and export API](project_import_export.md).

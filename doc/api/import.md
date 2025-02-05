---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Import API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use the Import API to import repositories from GitHub or Bitbucket Server.

## Import repository from GitHub

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/381902) in GitLab 15.8, GitLab no longer automatically creates namespaces or groups if the namespace or group name specified in `target_namespace` doesn't exist. GitLab also no longer falls back to using the user's personal namespace if the namespace or group name is taken or `target_namespace` is blank.
> - Requirement for Maintainer role instead of Developer role introduced in GitLab 16.0 and backported to GitLab 15.11.1 and GitLab 15.10.5.
> - `collaborators_import` key in `optional_stages` was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/398154) in GitLab 16.0.
> - Feature flag `github_import_extended_events` was introduced in GitLab 16.8. Disabled by default. This flag improves the performance of imports but disables the `single_endpoint_issue_events_import` optional stage.
> - Feature flag `github_import_extended_events` was [enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/435089) in GitLab 16.9.
> - Improved import performance made [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/435089) in GitLab 16.11. Feature flag `github_import_extended_events` removed.

Import your projects from GitHub to GitLab using the API.

Prerequisites:

- [Prerequisites for GitHub importer](../user/project/import/github.md#prerequisites).
- The namespace set in `target_namespace` must exist.
- The namespace can be your user namespace or an existing group that you have at least the Maintainer role for.

```plaintext
POST /import/github
```

| Attribute                  | Type    | Required | Description                                                                                                                                                                         |
|----------------------------|---------|----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `personal_access_token`    | string  | yes      | GitHub personal access token                                                                                                                                                        |
| `repo_id`                  | integer | yes      | GitHub repository ID                                                                                                                                                                |
| `new_name`                 | string  | no       | Name of the new project. Also used as the new path so must not start or end with a special character and must not contain consecutive special characters. |
| `target_namespace`         | string  | yes      | Namespace to import repository into. Supports subgroups like `/namespace/subgroup`. In GitLab 15.8 and later, must not be blank                                                     |
| `github_hostname`          | string  | no  | Custom GitHub Enterprise hostname. Do not set for GitHub.com. From GitLab 16.5 to GitLab 17.1, you must include the path `/api/v3`.                                                                    |
| `optional_stages`          | object  | no  | [Additional items to import](../user/project/import/github.md#select-additional-items-to-import). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/373705) in GitLab 15.5 |
| `timeout_strategy`          | string | no  | Strategy for handling import timeouts. Valid values are `optimistic` (continue to next stage of import) or `pessimistic` (fail immediately). Defaults to `pessimistic`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/422979) in GitLab 16.5. |
| `pagination_limit`          | integer | no  | Number of items retrieved per API request to GitHub. The default value is 100 items per page. For project imports from large repositories, reducing this to a lower number can reduce the risk of GitHub API endpoints returning `500` or `502` errors. However, decreasing the page size will result in longer migration times. |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/github" \
  --header "content-type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --data '{
    "personal_access_token": "aBc123abC12aBc123abC12abC123+_A/c123",
    "repo_id": "12345",
    "target_namespace": "group/subgroup",
    "new_name": "NEW-NAME",
    "github_hostname": "https://github.example.com",
    "optional_stages": {
      "single_endpoint_notes_import": true,
      "attachments_import": true,
      "collaborators_import": true
    }
}'
```

The following keys are available for `optional_stages`:

- `single_endpoint_issue_events_import`, for issue and pull request events import. This optional stage was removed in GitLab 16.9.
- `single_endpoint_notes_import`, for an alternative and more thorough comments import.
- `attachments_import`, for Markdown attachments import.
- `collaborators_import`, for importing direct repository collaborators who are not outside collaborators.

For more information, see [Select additional items to import](../user/project/import/github.md#select-additional-items-to-import).

Example response:

```json
{
    "id": 27,
    "name": "my-repo",
    "full_path": "/root/my-repo",
    "full_name": "Administrator / my-repo",
    "refs_url": "/root/my-repo/refs",
    "import_source": "my-github/repo",
    "import_status": "scheduled",
    "human_import_status_name": "scheduled",
    "provider_link": "/my-github/repo",
    "relation_type": null,
    "import_warning": null
}
```

### Import a public project through the API using a group access token

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/362683) in GitLab 15.7, projects are not imported into a [bot user's](../user/group/settings/group_access_tokens.md#bot-users-for-groups) namespace in any circumstances. Projects imported into a bot user's namespace could not be deleted by users with valid tokens, which represented a security risk.

When you import a project from GitHub to GitLab through the API using a group access
token:

- The GitLab project inherits the original project's visibility settings. As a result, the project is publicly accessible if the original project is public.
- If the `path` or `target_namespace` does not exist, the project import fails.

### Cancel GitHub project import

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/364783) in GitLab 15.5.

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
> - [Enabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/386579) in GitLab 15.10.
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

Import your projects from Bitbucket Server to GitLab using the API.

The Bitbucket Project Key is only used for finding the repository in Bitbucket.
You must specify a `target_namespace` if you want to import the repository to a GitLab group.
If you do not specify `target_namespace`, the project imports to your personal user namespace.

Prerequisites:

- For more information, see [prerequisites for Bitbucket Server importer](../user/project/import/bitbucket_server.md).

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
| `new_name` | string | no | Name of the new project. Also used as the new path so must not start or end with a special character and must not contain consecutive special characters. Between GitLab 15.1 and GitLab 16.9, the project path [was copied](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88845) from Bitbucket instead. In GitLab 16.10, the behavior was [changed back](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145793) to the original behavior. |
| `target_namespace` | string | no | Namespace to import repository into. Supports subgroups like `/namespace/subgroup` |
| `timeout_strategy`          | string | no  | Strategy for handling import timeouts. Valid values are `optimistic` (continue to next stage of import) or `pessimistic` (fail immediately). Defaults to `pessimistic`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/422979) in GitLab 16.5. |

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
    "bitbucket_server_repo": "my-repo",
    "new_name": "NEW-NAME"
}'
```

## Import repository from Bitbucket Cloud

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/215036) in GitLab 17.0.

Import your projects from Bitbucket Cloud to GitLab using by the API.

Prerequisites:

- The [prerequisites for Bitbucket Cloud importer](../user/project/import/bitbucket.md).
- A [Bitbucket Cloud app password](../user/project/import/bitbucket.md#generate-a-bitbucket-cloud-app-password).

```plaintext
POST /import/bitbucket
```

| Attribute                | Type   | Required | Description |
|:-------------------------|:-------|:---------|:------------|
| `bitbucket_username`     | string | yes      | Bitbucket Cloud username |
| `bitbucket_app_password` | string | yes      | Bitbucket Cloud app password |
| `repo_path`              | string | yes      | Path to repository |
| `target_namespace`       | string | yes      | Namespace to import repository into. Supports subgroups like `/namespace/subgroup` |
| `new_name`               | string | no       | Name of the new project. Also used as the new path so must not start or end with a special character and must not contain consecutive special characters. |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/bitbucket" \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data '{
    "bitbucket_username": "bitbucket_username",
    "bitbucket_app_password": "bitbucket_app_password",
    "repo_path": "username/my_project",
    "target_namespace": "my_group/my_subgroup",
    "new_name": "new_project_name"
}'
```

## Related topics

- [Group migration by direct transfer API](bulk_imports.md).
- [Group import and export API](group_import_export.md).
- [Project import and export API](project_import_export.md).

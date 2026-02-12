---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Use these tools to interact with GitLab through the GitLab MCP server.
title: GitLab MCP server tools
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

> [!warning]
> To provide feedback on this feature, leave a comment on [issue 561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564).

The GitLab MCP server provides a set of tools that integrate with your existing GitLab workflows.
You can use these tools to interact directly with GitLab and perform common GitLab operations.

## `get_mcp_server_version`

Returns the current version of the GitLab MCP server.

Example:

```plaintext
What version of the GitLab MCP server am I connected to?
```

## `create_issue`

Creates a new issue in a GitLab project.

| Parameter      | Type              | Required | Description |
|----------------|-------------------|----------|-------------|
| `id`           | string            | Yes      | ID or URL-encoded path of the project. |
| `title`        | string            | Yes      | Title of the issue. |
| `description`  | string            | No       | Description of the issue. |
| `assignee_ids` | array of integers | No       | Array of IDs of assigned users. |
| `milestone_id` | integer           | No       | ID of the milestone. |
| `labels`       | array of strings  | No       | Array of label names. |
| `confidential` | boolean           | No       | Sets the issue to confidential. Default is `false`. |
| `epic_id`      | integer           | No       | ID of the linked epic. |

Example:

```plaintext
Create a new issue titled "Fix login bug" in project 123 with description
"Users cannot log in with special characters in password"
```

## `get_issue`

Retrieves detailed information about a specific GitLab issue.

| Parameter   | Type    | Required | Description |
|-------------|---------|----------|-------------|
| `id`        | string  | Yes      | ID or URL-encoded path of the project. |
| `issue_iid` | integer | Yes      | Internal ID of the issue. |

Example:

```plaintext
Get details for issue 42 in project 123
```

## `create_merge_request`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/571243) in GitLab 18.5.
- `assignee_ids`, `reviewer_ids`, `description`, `labels`, and `milestone_id` [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217458) in GitLab 18.8.

{{< /history >}}

Creates a merge request in a GitLab project.

| Parameter           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | string            | Yes      | ID or URL-encoded path of the project. |
| `title`             | string            | Yes      | Title of the merge request. |
| `source_branch`     | string            | Yes      | Name of the source branch. |
| `target_branch`     | string            | Yes      | Name of the target branch. |
| `target_project_id` | integer           | No       | ID of the target project. |
| `assignee_ids`      | array of integers | No       | Array of IDs of merge request assignees. Set to `0` or an empty value to unassign all assignees. |
| `reviewer_ids`      | array of integers | No       | Array of IDs of merge request reviewers. Set to `0` or an empty value to unassign all reviewers. |
| `description`       | string            | No       | Description of the merge request. |
| `labels`            | array of strings  | No       | Array of label names. Set to an empty string to unassign all labels. |
| `milestone_id`      | integer           | No       | ID of the milestone. |

Example:

```plaintext
Create a merge request in project gitlab-org/gitlab titled "Bug fix broken specs"
from branch "fix/specs-broken" into "master" and enable squash
```

## `get_merge_request`

Retrieves detailed information about a specific GitLab merge request.

| Parameter           | Type    | Required | Description |
|---------------------|---------|----------|-------------|
| `id`                | string  | Yes      | ID or URL-encoded path of the project. |
| `merge_request_iid` | integer | Yes      | Internal ID of the merge request. |

Example:

```plaintext
Get details for merge request 15 in project gitlab-org/gitlab
```

## `get_merge_request_commits`

Retrieves the list of commits in a specific GitLab merge request.

| Parameter           | Type    | Required | Description |
|---------------------|---------|----------|-------------|
| `id`                | string  | Yes      | ID or URL-encoded path of the project. |
| `merge_request_iid` | integer | Yes      | Internal ID of the merge request. |
| `per_page`          | integer | No       | Number of commits per page. |
| `page`              | integer | No       | Current page number. |

Example:

```plaintext
Show me all commits in merge request 42 from project 123
```

## `get_merge_request_diffs`

Retrieves the diffs for a specific GitLab merge request.

| Parameter           | Type    | Required | Description |
|---------------------|---------|----------|-------------|
| `id`                | string  | Yes      | ID or URL-encoded path of the project. |
| `merge_request_iid` | integer | Yes      | Internal ID of the merge request. |
| `per_page`          | integer | No       | Number of diffs per page. |
| `page`              | integer | No       | Current page number. |

Example:

```plaintext
What files were changed in merge request 25 in the gitlab project?
```

## `get_merge_request_pipelines`

Retrieves the pipelines for a specific GitLab merge request.

| Parameter           | Type    | Required | Description |
|---------------------|---------|----------|-------------|
| `id`                | string  | Yes      | ID or URL-encoded path of the project. |
| `merge_request_iid` | integer | Yes      | Internal ID of the merge request. |

Example:

```plaintext
Show me all pipelines for merge request 42 in project gitlab-org/gitlab
```

## `get_pipeline_jobs`

Retrieves the jobs for a specific GitLab CI/CD pipeline.

| Parameter     | Type    | Required | Description |
|---------------|---------|----------|-------------|
| `id`          | string  | Yes      | ID or URL-encoded path of the project. |
| `pipeline_id` | integer | Yes      | ID of the pipeline. |
| `per_page`    | integer | No       | Number of jobs per page. |
| `page`        | integer | No       | Current page number. |

Example:

```plaintext
Show me all jobs in pipeline 12345 for project gitlab-org/gitlab
```

## `create_workitem_note`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/581890) in GitLab 18.7.

{{< /history >}}

Creates a new note (comment) on a GitLab work item.

| Parameter       | Type    | Required | Description |
|-----------------|---------|----------|-------------|
| `body`          | string  | Yes      | Content of the note. |
| `url`           | string  | No       | URL for the work item. Required if `group_id` or `project_id` and `work_item_iid` are missing. |
| `group_id`      | string  | No       | ID or path of the group. Required if `url` and `project_id` are missing. |
| `project_id`    | string  | No       | ID or path of the project. Required if `url` and `group_id` are missing. |
| `work_item_iid` | integer | No       | Internal ID of the work item. Required if `url` is missing. |
| `internal`      | boolean | No       | Marks the note as internal (visible only to users with the Reporter, Developer, Maintainer, or Owner role for the project). Default is `false`. |
| `discussion_id` | string  | No       | Global ID of the discussion to reply to (in the format `gid://gitlab/Discussion/<id>`). |

Example:

```plaintext
Add a comment "This looks good to me" to work item 42 in project gitlab-org/gitlab
```

## `get_workitem_notes`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/581892) in GitLab 18.7.

{{< /history >}}

Retrieves all notes (comments) for a specific GitLab work item.

| Parameter       | Type    | Required | Description |
|-----------------|---------|----------|-------------|
| `url`           | string  | No       | URL for the work item. Required if `group_id` or `project_id` and `work_item_iid` are missing. |
| `group_id`      | string  | No       | ID or path of the group. Required if `url` and `project_id` are missing. |
| `project_id`    | string  | No       | ID or path of the project. Required if `url` and `group_id` are missing. |
| `work_item_iid` | integer | No       | Internal ID of the work item. Required if `url` is missing. |
| `after`         | string  | No       | Cursor for forward pagination. |
| `before`        | string  | No       | Cursor for backward pagination. |
| `first`         | integer | No       | Number of notes to return for forward pagination. |
| `last`          | integer | No       | Number of notes to return for backward pagination. |

Example:

```plaintext
Show me all comments on work item 42 in project gitlab-org/gitlab
```

## `search`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/566143) in GitLab 18.4.
- Searching groups and projects and ordering and sorting results [added](https://gitlab.com/gitlab-org/gitlab/-/issues/571132) in GitLab 18.6.
- [Renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214734) from `gitlab_search` to `search` in GitLab 18.8.

{{< /history >}}

Searches for a term across the entire GitLab instance with the search API.
This tool is available for global, group, and project search.
Available scopes depend on the [search type](../../search/_index.md).

| Parameter      | Type             | Required | Description |
|----------------|------------------|----------|-------------|
| `scope`        | string           | Yes      | Search scope (for example, `issues`, `merge_requests`, or `projects`). |
| `search`       | string           | Yes      | Search term. |
| `group_id`     | string           | No       | ID or URL-encoded path of the group you want to search. |
| `project_id`   | string           | No       | ID or URL-encoded path of the project you want to search. |
| `state`        | string           | No       | State of search results (for `issues` and `merge_requests`). |
| `confidential` | boolean          | No       | Filters results by confidentiality (for `issues`). Default is `false`. |
| `fields`       | array of strings | No       | Array of fields you want to search (for `issues` and `merge_requests`). |
| `order_by`     | string           | No       | Attribute to order results by. Default is `created_at` for basic search and relevance for advanced search. |
| `sort`         | string           | No       | Sort direction for results. Default is `desc`. |
| `per_page`     | integer          | No       | Number of results per page. Default is `20`. |
| `page`         | integer          | No       | Current page number. Default is `1`. |

Example:

```plaintext
Search issues for "flaky test" across GitLab
```

## `search_labels`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218121) in GitLab 18.9.

{{< /history >}}

Searches for labels in a GitLab project or group.

| Parameter    | Type    | Required | Description |
|--------------|---------|----------|-------------|
| `full_path`  | string  | Yes      | Full path of the project or group (for example, `namespace/project`). |
| `is_project` | boolean | Yes      | Whether to search in a project (`true`) or group (`false`). |
| `search`     | string  | No       | Search term to filter labels by title. |

When you search group labels, the results include labels from ancestor and descendant groups.

Example:

```plaintext
Show me all labels in project gitlab-org/gitlab
```

## `semantic_code_search`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/569624) as an [experiment](../../../policy/development_stages_support.md#experiment) in GitLab 18.5 [with a flag](../../../administration/feature_flags/_index.md) named `code_snippet_search_graphqlapi`. Disabled by default.
- Search by project path [added](https://gitlab.com/gitlab-org/gitlab/-/issues/575234) in GitLab 18.6.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/568359) from experiment to [beta](../../../policy/development_stages_support.md#beta) in GitLab 18.7. Feature flag `code_snippet_search_graphqlapi` removed.
- [Added](https://gitlab.com/gitlab-org/gitlab/-/issues/581105) to the GitLab UI in GitLab 18.7 [with a flag](../../../administration/feature_flags/_index.md) named `mcp_client`. Disabled by default.

{{< /history >}}

Searches for relevant code snippets in a GitLab project.
For more information, including setup and enablement,
see [semantic code search](../semantic_code_search.md).

| Parameter        | Type    | Required | Description |
|------------------|---------|----------|-------------|
| `semantic_query` | string  | Yes      | Search query for the code. |
| `project_id`     | string  | Yes      | ID or path of the project. |
| `directory_path` | string  | No       | Path of the directory (for example, `app/services/`). |
| `knn`            | integer | No       | Number of nearest neighbors used to find similar code snippets. Default is `64`. |
| `limit`          | integer | No       | Maximum number of results to return. Default is `20`. |

For best results, describe the functionality or behavior you're interested in
rather than using generic keywords or specific function or variable names.

Example:

```plaintext
How are authorizations managed in this project?
```

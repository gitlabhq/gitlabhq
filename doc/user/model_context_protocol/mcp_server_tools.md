---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Use these tools to interact with GitLab through the GitLab MCP server.
title: GitLab MCP server tools
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

> [!warning]
> To provide feedback on this feature, leave a comment on [issue 561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564).

The GitLab MCP server provides a set of tools that integrate with your existing GitLab workflows.
You can use these tools to interact directly with GitLab and perform common GitLab operations.

## `get_mcp_server_version`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200105) in GitLab 18.3.

{{< /history >}}

Returns the current version of the GitLab MCP server.

Example:

```plaintext
What version of the GitLab MCP server am I connected to?
```

## `create_issue`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055) in GitLab 18.4.

{{< /history >}}

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

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201838) in GitLab 18.4.

{{< /history >}}

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

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201838) in GitLab 18.4.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/605878) to accept `url` and return associated data facets in GitLab 19.3.

{{< /history >}}

Retrieves a merge request and, optionally, its diffs, commits, notes, pipelines, or discussions.
Only the base merge request is returned unless you request associated data with the `include` parameter.

| Parameter           | Type    | Required | Description |
|---------------------|---------|----------|-------------|
| `url`               | string  | No       | GitLab URL of the merge request. Provide this, or `project_id` and `merge_request_iid`. |
| `project_id`        | string  | No       | ID or URL-encoded path of the project. Required if `url` is missing. |
| `merge_request_iid` | integer | No       | Internal ID of the merge request. Required if `url` is missing. |
| `include`           | array   | No       | Associated facets to return with the merge request. One of `diffs`, `commits`, `notes`, `pipelines`, or `discussions`. Limited to one facet per call. |
| `notes_after`       | string  | No       | Cursor for forward pagination of notes. Applies only when `include` is `["notes"]`. |
| `notes_first`       | integer | No       | Number of notes to return after the cursor, up to 100. Applies only when `include` is `["notes"]`. |

The `diffs` facet returns change statistics only: overall totals and per-file additions and
deletions. To get patch text, use `get_merge_request_diffs`.

Example:

```plaintext
Get merge request 15 in project gitlab-org/gitlab with its commits
```

## `list_merge_requests`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/246413) in GitLab 19.3.

{{< /history >}}

Lists or searches merge requests in a GitLab project, returning compact merge request metadata.

| Parameter           | Type    | Required | Description |
|---------------------|---------|----------|-------------|
| `url`               | string  | No       | URL of the project. Provide exactly one of `url` or `project_id`. |
| `project_id`        | string  | No       | ID or full path of the project. Provide exactly one of `url` or `project_id`. |
| `author_username`   | string  | No       | Filter by the username of the merge request author. |
| `assignee_username` | string  | No       | Filter by the username of an assignee. |
| `reviewer_username` | string  | No       | Filter by the username of a reviewer. |
| `state`             | string  | No       | Filter by state. One of `opened`, `closed`, `merged`, `locked`, or `all`. Omit to include any state. |
| `scope`             | string  | No       | Filter relative to the authenticated user. One of `created_by_me`, `assigned_to_me`, or `review_requested`. An explicit username wins for that field. |
| `milestone`         | string  | No       | Filter by the title of the milestone. |
| `labels`            | string  | No       | Comma-separated list of label names. Only merge requests with all of these labels are returned. |
| `search`            | string  | No       | Search query matched against merge request title and description. |
| `after`             | string  | No       | Cursor for forward pagination. |
| `first`             | integer | No       | Number of merge requests to return for forward pagination. Default is 20, maximum is 100. |

To retrieve a single merge request in full detail, use `get_merge_request`. Its diffs, commits, and
notes are available from `get_merge_request_diffs`, `get_merge_request_commits`, and
`get_merge_request_notes`. For full-text search across resource types, use `search`.

Example:

```plaintext
List my open merge requests in gitlab-org/gitlab
```

## `get_merge_request_commits`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055) in GitLab 18.4.

{{< /history >}}

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

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055) in GitLab 18.4.

{{< /history >}}

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

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055) in GitLab 18.4.

{{< /history >}}

Retrieves the pipelines for a specific GitLab merge request.

| Parameter           | Type    | Required | Description |
|---------------------|---------|----------|-------------|
| `id`                | string  | Yes      | ID or URL-encoded path of the project. |
| `merge_request_iid` | integer | Yes      | Internal ID of the merge request. |

Example:

```plaintext
Show me all pipelines for merge request 42 in project gitlab-org/gitlab
```

## `create_merge_request_note`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/597494) in GitLab 19.2.

{{< /history >}}

Adds a comment or reply to a discussion on a GitLab merge request as the authenticated user.

| Parameter           | Type    | Required | Description |
|---------------------|---------|----------|-------------|
| `url`               | string  | No       | URL of the GitLab merge request. Required if `project_id` and `merge_request_iid` are missing. |
| `project_id`        | string  | No       | ID or URL-encoded path of the project. Required if `url` is missing. |
| `merge_request_iid` | integer | No       | Internal ID of the merge request. Required if `url` is missing. |
| `body`              | string  | Yes      | Content of the note. Lines cannot start with `/` to avoid triggering quick actions (for example, `/merge`). |
| `discussion_id`     | string  | No       | Global ID of the discussion to reply to (in the format `gid://gitlab/Discussion/<id>`). If missing, creates a new top-level note. |

Example:

```plaintext
Reply "Thanks, fixed in the latest push" to merge request 42 in project gitlab-org/gitlab
```

## `get_merge_request_notes`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/597494) in GitLab 19.2.

{{< /history >}}

Retrieves the notes (comments and system notes) for a specific GitLab merge request.

| Parameter           | Type    | Required | Description                                                                                    |
|---------------------|---------|----------|--------------------------------------------------------------------------------------------------|
| `url`               | string  | No       | URL of the GitLab merge request. Required if `project_id` and `merge_request_iid` are missing.   |
| `project_id`        | string  | No       | ID or URL-encoded path of the project. Required if `url` is missing.                           |
| `merge_request_iid` | integer | No       | Internal ID of the merge request. Required if `url` is missing.                                |
| `after`             | string  | No       | Cursor for forward pagination.                                                                 |
| `before`            | string  | No       | Cursor for backward pagination.                                                                |
| `first`             | integer | No       | Number of notes to return for forward pagination.                                              |
| `last`              | integer | No       | Number of notes to return for backward pagination.                                             |

Each returned note includes its discussion ID, so related notes can be grouped into threads.

Example:

```plaintext
Show me all comments on merge request 5 in project gitlab-org/gitlab
```

## `add_branch`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/605877) in GitLab 19.3. `create_branch` is also accepted as an alias.

{{< /history >}}

Adds a branch to a GitLab project from a source ref.

| Parameter    | Type   | Required | Description |
|--------------|--------|----------|-------------|
| `url`        | string | No       | GitLab URL of the project. Provide this, or `project_id`. |
| `project_id` | string | No       | ID or path of the project. Required if `url` is not provided. |
| `branch`     | string | Yes      | Name of the new branch. |
| `ref`        | string | Yes      | Branch name or commit SHA to create the new branch from. |

Example:

```plaintext
Create a branch named feature/x from main in project gitlab-org/gitlab
```

## `get_pipeline_jobs`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055) in GitLab 18.4.

{{< /history >}}

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

## `get_job_log`

Retrieves the trace (log output) for a specific CI/CD job.

| Parameter | Type    | Required | Description |
|-----------|---------|----------|-------------|
| `id`      | string  | Yes      | ID or URL-encoded path of the project. |
| `job_id`  | integer | Yes      | ID of the job. |

Example:

```plaintext
Show me the log output for job 88 in project gitlab-org/gitlab
```

## `list_pipelines`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/605854) in GitLab 19.3.

{{< /history >}}

Lists pipelines in a GitLab project, with optional filters.

| Parameter        | Type    | Required | Description |
|------------------|---------|----------|-------------|
| `id`             | string  | Yes      | ID or URL-encoded path of the project. |
| `ref`            | string  | No       | Branch or tag name. Filters pipelines by ref. |
| `status`         | string  | No       | Filters pipelines by status (for example, `running`, `success`, `failed`). |
| `source`         | string  | No       | Filters pipelines by source (for example, `push`, `web`, `schedule`). |
| `created_after`  | string  | No       | Returns pipelines created after the specified datetime (ISO 8601 format). |
| `created_before` | string  | No       | Returns pipelines created before the specified datetime (ISO 8601 format). |
| `order_by`       | string  | No       | Orders pipelines by `id`, `status`, `ref`, `updated_at`, or `user_id`. Default is `id`. |
| `sort`           | string  | No       | Sort direction, `asc` or `desc`. Default is `desc`. |
| `page`           | integer | No       | Current page number. Default is `1`. |
| `per_page`       | integer | No       | Number of items per page. Default is `20`. |

Child pipelines are excluded from the results by default. To return only child pipelines, set `source` to `parent_pipeline`.

The default order (`id`, `desc`) returns pipelines with the highest ID first. ID order usually matches creation order, but the two aren't guaranteed to agree. Use `created_after` or `created_before` to filter by an explicit time boundary. A caller can page through results and stop at the first pipeline outside its target range.

Example:

```plaintext
List all failed pipelines on the main branch for project gitlab-org/gitlab
```

## `manage_pipeline`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/583826) in GitLab 18.10.
- [Removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/247806) the `list` action in favor of the `list_pipelines` tool in GitLab 19.3.

{{< /history >}}

Manages CI/CD pipelines in a GitLab project. To list pipelines, use the `list_pipelines` tool instead.

| Parameter     | Type    | Required    | Description |
|---------------|---------|-------------|-------------|
| `id`          | string  | Yes         | ID or URL-encoded path of the project. |
| `ref`         | string  | No          | Branch or tag name. If set, creates a new pipeline on a branch or tag. |
| `pipeline_id` | integer | No          | ID of the pipeline. If only this parameter is set, deletes a pipeline and all related data. |
| `retry`       | boolean | No          | If `true` and `pipeline_id` is set, retries failed or canceled pipeline jobs. |
| `cancel`      | boolean | No          | If `true` and `pipeline_id` is set, cancels all jobs in a running pipeline. |
| `name`        | string  | No          | Name of the pipeline. If this parameter and `pipeline_id` are set, updates the pipeline metadata. |
| `variables`   | array   | No          | Pipeline variables in array format (`[{key, value, variable_type}]`). |
| `inputs`      | hash    | No          | Pipeline input parameters as key-value pairs. |

Examples:

- Create a pipeline:

  ```plaintext
  Create a pipeline on the main branch for project gitlab-org/gitlab
  ```

- Update a pipeline:

  ```plaintext
  Rename pipeline 12345 to "My deploy pipeline" in project gitlab-org/gitlab
  ```

- Retry a pipeline:

  ```plaintext
  Retry failed jobs in pipeline 12345 for project gitlab-org/gitlab
  ```

- Cancel a pipeline:

  ```plaintext
  Cancel pipeline 12345 in project gitlab-org/gitlab
  ```

- Delete a pipeline:

  ```plaintext
  Delete pipeline 12345 in project gitlab-org/gitlab
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

## `link_work_items`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230221) in GitLab 19.0.

{{< /history >}}

Links a work item to one or more other work items with a relationship type.

| Parameter        | Type             | Required | Description |
|------------------|------------------|----------|-------------|
| `work_items_ids` | array of strings | Yes      | Global IDs of the work items to link to (in the format `gid://gitlab/WorkItem/<id>`). Maximum 10 items. |
| `url`            | string           | No       | URL for the source work item. Required if `group_id` or `project_id` and `work_item_iid` are missing. |
| `group_id`       | string           | No       | ID or path of the group. Required if `url` and `project_id` are missing. |
| `project_id`     | string           | No       | ID or path of the project. Required if `url` and `group_id` are missing. |
| `work_item_iid`  | integer          | No       | Internal ID of the source work item. Required if `url` is missing. |
| `link_type`      | string           | No       | Type of relationship. One of `relates_to`, `blocks`, or `blocked_by`. Default is `relates_to`. The `blocks` and `blocked_by` types require GitLab Premium or Ultimate. |

Example:

```plaintext
Mark work item 42 in project gitlab-org/gitlab as blocked by work item 40
```

## `get_saved_view_work_items`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227911) in GitLab 18.11.

{{< /history >}}

Retrieves a saved view and its list of work items from a namespace. The tool applies the
filters and the sort order in the saved view to the returned work items.

| Parameter       | Type    | Required | Description |
|-----------------|---------|----------|-------------|
| `saved_view_id` | string  | Yes      | Global ID of the saved view (in the format `gid://gitlab/WorkItems::SavedViews::SavedView/<id>`). |
| `url`           | string  | No       | URL for the namespace (project or group). Required if `group_id` or `project_id` is missing. |
| `group_id`      | string  | No       | ID or path of the group. Required if `url` and `project_id` are missing. |
| `project_id`    | string  | No       | ID or path of the project. Required if `url` and `group_id` are missing. |
| `after`         | string  | No       | Cursor for forward pagination. |
| `first`         | integer | No       | Number of work items to return. Maximum 100. |

Example:

```plaintext
Show me the work items in this saved view: <URL>
```

## `search`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/566143) in GitLab 18.4.
- Searching groups and projects and ordering and sorting results [added](https://gitlab.com/gitlab-org/gitlab/-/issues/571132) in GitLab 18.6.
- [Renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214734) from `gitlab_search` to `search` in GitLab 18.8.

{{< /history >}}

Searches for a term across the entire GitLab instance with the search API.
This tool is available for global, group, and project search.
Available scopes depend on the [search type](../search/_index.md).

| Parameter      | Type             | Required | Description |
|----------------|------------------|----------|-------------|
| `scope`        | string           | Yes      | Search scope (for example, `work_items`, `merge_requests`, or `projects`). |
| `search`       | string           | Yes      | Search term. |
| `group_id`     | string           | No       | ID or URL-encoded path of the group you want to search. |
| `project_id`   | string           | No       | ID or URL-encoded path of the project you want to search. |
| `state`        | string           | No       | State of search results (for `work_items` and `merge_requests`). |
| `confidential` | boolean          | No       | Filters results by confidentiality (for `work_items`). Default is `false`. |
| `fields`       | array of strings | No       | Array of fields you want to search (for `work_items` and `merge_requests`). |
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
| `full_path`  | string  | Yes      | Full path of the project or group (for example, `group/project`). |
| `is_project` | boolean | Yes      | Whether to search in a project (`true`) or group (`false`). |
| `search`     | string  | No       | Search term to filter labels by title. |

When you search group labels, the results include labels from ancestor and descendant groups.

Example:

```plaintext
Show me all labels in project gitlab-org/gitlab
```

## `list_wiki_pages`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240973) in GitLab 19.3.

{{< /history >}}

Lists the wiki pages in a GitLab project or group.

| Parameter    | Type    | Required | Description |
|--------------|---------|----------|-------------|
| `project_id` | string  | No       | Full path or numeric ID of the project (for example, `gitlab-org/gitlab` or `278964`). |
| `group_id`   | string  | No       | Full path or numeric ID of the group (for example, `gitlab-org` or `9970`). |
| `first`      | integer | No       | Number of wiki pages to return for forward pagination (maximum 100). |
| `after`      | string  | No       | Cursor for forward pagination. |

Provide only one `project_id` or `group_id`.
Each call returns a single page of results.
If more pages exist, the response includes an `end_cursor` you can pass as `after` to fetch the next page.

Example:

```plaintext
List the wiki pages in gitlab-org/gitlab
```

## `semantic_code_search`

{{< details >}}

- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/569624) as an [experiment](../../policy/development_stages_support.md#experiment) in GitLab 18.5 [with a feature flag](../../administration/feature_flags/_index.md) named `code_snippet_search_graphqlapi`. Disabled by default.
- Search by project path [added](https://gitlab.com/gitlab-org/gitlab/-/issues/575234) in GitLab 18.6.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/568359) from experiment to [beta](../../policy/development_stages_support.md#beta) in GitLab 18.7. Feature flag `code_snippet_search_graphqlapi` removed.
- [Added](https://gitlab.com/gitlab-org/gitlab/-/issues/581105) to the GitLab UI in GitLab 18.7 [with a feature flag](../../administration/feature_flags/_index.md) named `mcp_client`. Disabled by default.
- [Updated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228569) to use the [REST API](../../api/search.md#semantic-search) in GitLab 18.11 [with a feature flag](../../administration/feature_flags/_index.md) named `mcp_semantic_code_search_use_rest_api`. Disabled by default.
- Using the REST API [generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239364) in GitLab 19.1. Feature flag `mcp_semantic_code_search_use_rest_api` removed.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

Searches for relevant code snippets in a GitLab project.
For more information, including setup and enablement,
see [semantic code search](../gitlab_duo/semantic_code_search.md).

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

## `attach_scan_profile`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240685) in GitLab 19.2.

{{< /history >}}

Attaches the given security scan profile to the specified projects, or to all projects under the specified groups.

| Parameter                  | Type             | Required | Description |
|----------------------------|------------------|----------|-------------|
| `security_scan_profile_id` | string           | Yes      | Global ID of the security scan profile (for example, `gid://gitlab/Security::ScanProfile/1`). |
| `project_ids`              | array of strings | No       | Array of global IDs of projects (for example, `[gid://gitlab/Project/1]`). This is required unless `group_ids` is provided. |
| `group_ids`                | array of strings | No       | Array of global IDs of groups (for example, `[gid://gitlab/Group/1]`). This is required unless `project_ids` is provided. |

Example:

```plaintext
Attach `gid://gitlab/Security::ScanProfile/1` to all projects under `gid://gitlab/Group/1`.
```

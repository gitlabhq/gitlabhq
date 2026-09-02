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

## `add_commit`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/605876) in GitLab 19.3.

{{< /history >}}

Adds a commit with one or more file actions to a branch in a single call.

| Parameter        | Type             | Required | Description |
|------------------|------------------|----------|-------------|
| `commit_message` | string           | Yes      | Commit message. |
| `actions`        | array of objects | Yes      | File actions to commit as a single batch. |
| `branch`         | string           | Yes      | Name of the branch to commit into. |
| `project_id`     | string           | No       | ID or path of the project. Required if `url` is not provided. |
| `url`            | string           | No       | GitLab URL of the project. Required if `project_id` is not provided. |
| `start_branch`   | string           | No       | Name of the branch to start the new branch from. Required when `branch` does not exist. |

Each object in `actions` accepts the following fields:

| Field              | Type    | Required | Description |
|--------------------|---------|----------|-------------|
| `action`           | string  | Yes      | The action to perform: `create`, `update`, `delete`, `move`, or `chmod`. |
| `file_path`        | string  | Yes      | Full path to the file. |
| `content`          | string  | No       | File content. Used by `create`, `update`, and `move`. Mutually exclusive with `old_str` and `new_str`. |
| `old_str`          | string  | No       | Existing text to replace in an `update` action. Requires `new_str`. |
| `new_str`          | string  | No       | Replacement text for `old_str` in an `update` action. |
| `previous_path`    | string  | No       | Original file path. Required for `move`. |
| `encoding`         | string  | No       | Encoding of `content`: `text` or `base64`. Default is `text`. |
| `last_commit_id`   | string  | No       | Last known commit ID for the file, used for optimistic concurrency. |
| `execute_filemode` | boolean | No       | Whether the file is executable. Required for `chmod`. |

Partial edits replace exactly one occurrence of `old_str`. If it occurs more than once, provide more surrounding
context. Partial edits read the complete file on the server and are subject to the 20 MB GraphQL blob request limit.

Example:

```plaintext
In project gitlab-org/gitlab, create README.md on branch "docs-update"
with the content "# New title" and commit message "Add README"
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

## `save_merge_request`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/571243) as `create_merge_request` in GitLab 18.5.
- `assignee_ids`, `reviewer_ids`, `description`, `labels`, and `milestone_id` [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217458) in GitLab 18.8.
- Renamed to `save_merge_request` and extended to update merge requests in GitLab 19.3. The `create_merge_request` and `update_merge_request` names remain as aliases.

{{< /history >}}

Creates or updates a merge request in a GitLab project.
The presence of `merge_request_iid` selects the operation: omit it to create a merge request, or provide it to update an existing one.

| Parameter              | Type              | Required | Description |
|------------------------|-------------------|----------|-------------|
| `project_id`           | string            | Yes      | ID or full path of the project. |
| `merge_request_iid`    | integer           | No       | Internal ID of the merge request. Provide to update an existing merge request; omit to create one. |
| `title`                | string            | No       | Title of the merge request. Required when creating. |
| `source_branch`        | string            | No       | Name of the source branch. Required when creating. |
| `target_branch`        | string            | No       | Name of the target branch. Required when creating. |
| `target_project_id`    | integer           | No       | ID of the target project. Applies when creating. |
| `description`          | string            | No       | Description of the merge request. |
| `labels`               | array of strings  | No       | Label names. Replaces all existing labels. Pass an empty array to remove all labels. |
| `add_labels`           | array of strings  | No       | Label names to add. Applies when updating. |
| `remove_labels`        | array of strings  | No       | Label names to remove. Applies when updating. |
| `assignees`            | array of strings  | No       | Usernames to assign. Alternative to `assignee_ids`; provide one. Pass an empty array to remove all assignees. |
| `assignee_ids`         | array of integers | No       | User IDs to assign. Alternative to `assignees`; provide one. Pass an empty array to remove all assignees. |
| `reviewers`            | array of strings  | No       | Usernames to request review from. Alternative to `reviewer_ids`; provide one. Pass an empty array to remove all reviewers. |
| `reviewer_ids`         | array of integers | No       | User IDs to request review from. Alternative to `reviewers`; provide one. Pass an empty array to remove all reviewers. |
| `milestone_id`         | integer           | No       | ID of the milestone. |
| `milestone`            | string            | No       | Title of a project or ancestor-group milestone to assign. Mutually exclusive with `milestone_id`. |
| `remove_source_branch` | boolean           | No       | Remove the source branch when the merge request is merged. |
| `squash`               | boolean           | No       | Squash commits into a single commit when merging. |
| `state_event`          | string            | No       | State transition to perform. One of `close` or `reopen`. Applies when updating. |
| `discussion_locked`    | boolean           | No       | Lock the merge request discussion. Applies when updating. |
| `allow_collaboration`  | boolean           | No       | Allow commits from members who can merge to the target branch. Applies when updating. |

Examples:

```plaintext
Create a merge request in project gitlab-org/gitlab titled "Bug fix broken specs"
from branch "fix/specs-broken" into "master" and enable squash
```

```plaintext
Update merge request 42 in project gitlab-org/gitlab to add the "bug" label and close it
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

## `list_duo_sessions`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248587) in GitLab 19.3.

{{< /history >}}

Lists your GitLab Duo Agent Platform sessions, excluding Duo Chat sessions.
Each session includes its individual status, goal preview, flow definition, and creation timestamp.
Project sessions also include a session URL.
The goal preview might be truncated.

| Parameter      | Type    | Required | Description |
|----------------|---------|----------|-------------|
| `url`          | string  | No       | GitLab URL of the project to filter sessions by. Do not use with `project_id`. |
| `project_id`   | string  | No       | Numeric ID or full path of the project to filter sessions by. Do not use with `url`. |
| `status_group` | string  | No       | Session status group. One of `active`, `paused`, `awaiting_input`, `completed`, `failed`, or `canceled`. |
| `after`        | string  | No       | Cursor for forward pagination. |
| `first`        | integer | No       | Number of sessions to return for forward pagination. Default is 20, maximum is 100. |

The `status_group` filter can return sessions with multiple individual statuses.
Each call returns a single page of results.
If more pages exist, the response includes `pageInfo.endCursor` that you can pass as `after`.

Example:

```plaintext
List my active Duo Agent Platform sessions in gitlab-org/gitlab
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

## `save_note`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/605848) in GitLab 19.4.
- [Renamed](https://gitlab.com/gitlab-org/gitlab/-/work_items/605848) from `create_merge_request_note` in GitLab 19.4. `create_merge_request_note` continues to work as an alias.
- [Renamed](https://gitlab.com/gitlab-org/gitlab/-/work_items/605848) from `create_workitem_note` in GitLab 19.4. `create_workitem_note` continues to work as an alias.

{{< /history >}}

Adds a comment to a GitLab merge request or work item, or replies to an existing discussion thread,
as the authenticated user.

| Parameter           | Type    | Required | Description |
|---------------------|---------|----------|-------------|
| `url`               | string  | No       | URL of the merge request or work item. The URL determines the target type. |
| `project_id`        | string  | No       | ID or path of the project. Required with `merge_request_iid`, and with `work_item_iid` for project-level work items. |
| `group_id`          | string  | No       | ID or path of the group. Required with `work_item_iid` for group-level work items. |
| `merge_request_iid` | integer | No       | Internal ID of the merge request. Provide with `project_id`. Mutually exclusive with `work_item_iid`. |
| `work_item_iid`     | integer | No       | Internal ID of the work item. Provide with `project_id` or `group_id`. Mutually exclusive with `merge_request_iid`. |
| `body`              | string  | Yes      | Content of the note. Lines cannot start with `/` to avoid triggering quick actions (for example, `/merge`). |
| `internal`          | boolean | No       | Marks the note as internal (visible only to members with at least the Reporter role). Default is `false`. |
| `discussion_id`     | string  | No       | Global ID of the discussion to reply to (in the format `gid://gitlab/Discussion/<id>`). If missing, creates a new top-level note. |

Examples:

- Comment on a merge request:

  ```plaintext
  Reply "Thanks, fixed in the latest push" to merge request 42 in project gitlab-org/gitlab
  ```

- Comment on a work item:

  ```plaintext
  Add a comment "This looks good to me" to work item 42 in project gitlab-org/gitlab
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

## `save_merge_request_review`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/605881) in GitLab 19.4.

{{< /history >}}

Writes merge request review artifacts as the authenticated user. Each call performs
exactly one operation, selected with the `method` parameter:

| Method               | Action |
|----------------------|--------|
| `create_note`        | Adds a top-level comment. |
| `reply_discussion`   | Replies in an existing discussion. |
| `create_diff_note`   | Comments on a specific diff line. |
| `resolve_discussion` | Resolves or unresolves a discussion. |
| `submit_review`      | Posts multiple diff comments and an optional summary in one call. |
| `post_duo_review`    | Asks GitLab Duo to review the merge request. Requires GitLab Duo Code Review. |
| `approve`            | Approves the merge request. Already-approved calls succeed with status `already_approved`. |
| `unapprove`          | Removes your approval. Calls without a prior approval succeed with status `not_approved`. |

Responses from `post_duo_review`, `approve`, and `unapprove` include the merge request's
current `diff_head_sha`, so you can tell whether a standing approval or review still covers
the latest commits.

| Parameter           | Type    | Required | Description |
|---------------------|---------|----------|-------------|
| `url`               | string  | No       | URL of the GitLab merge request. Required if `project_id` and `merge_request_iid` are missing. |
| `project_id`        | string  | No       | ID or path of the project. Required if `url` is missing. |
| `merge_request_iid` | integer | No       | Internal ID of the merge request. Required if `url` is missing. |
| `method`            | string  | Yes      | The operation to perform. Parameters that belong to a different method are rejected. |
| `body`              | string  | No       | Note text. Required for `create_note`, `reply_discussion`, and `create_diff_note`. Lines cannot start with `/` to avoid triggering quick actions (for example, `/merge`). |
| `discussion_id`     | string  | No       | Discussion to act on. Required for `reply_discussion` and `resolve_discussion`. Accepts a global ID or a bare discussion ID. |
| `internal`          | boolean | No       | For `create_note`, marks the note as internal. |
| `resolved`          | boolean | No       | For `resolve_discussion`: `true` resolves, `false` unresolves. Required for that method. |
| `old_path`          | string  | No       | For `create_diff_note`, the file path before the change. Provide `old_path` or `new_path`, or both. |
| `new_path`          | string  | No       | For `create_diff_note`, the file path after the change. |
| `old_line`          | integer | No       | For `create_diff_note`, the line number in the old version. Provide `old_line` or `new_line`, or both. |
| `new_line`          | integer | No       | For `create_diff_note`, the line number in the new version. |
| `comments`          | array   | No       | For `submit_review`, 1-20 diff comments. Each entry takes `file` and `body` (required), and `old_line`, `new_line`, and `suggestion` (optional). Required for that method. `file` is the post-change path; for renamed files, use `create_diff_note` instead. |
| `verdict`           | string  | No       | For `submit_review`, an overall verdict prefixed to the summary note. |
| `summary`           | string  | No       | For `submit_review`, a summary note posted after the diff comments. |
| `summary_internal`  | boolean | No       | For `submit_review`, marks the summary note as internal. |
| `sha`               | string  | No       | For `approve`, a head SHA guard. When given and it no longer matches the merge request head, the approval is refused. Pass the full 40-character `diff_head_sha` returned by `get_merge_request`. |

Example:

```plaintext
Review merge request 42 in project gitlab-org/gitlab and leave your findings as diff comments with a summary
```

## `list_project_members`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251379) in GitLab 19.4.

{{< /history >}}

Lists the members of a GitLab project with their role and access level.

| Parameter           | Type    | Required | Description |
|---------------------|---------|----------|-------------|
| `project_id`        | string  | Yes      | Full path or numeric ID of the project (for example, `gitlab-org/gitlab` or `278964`). |
| `include_inherited` | boolean | No       | Also return members who inherit their role from a parent group or a subgroup of the project. Defaults to `false`. |
| `query`             | string  | No       | Return only members whose name or username contains this text. |
| `first`             | integer | No       | Number of members to return for forward pagination (default 20, maximum 100). |
| `after`             | string  | No       | Cursor for forward pagination. |

For each member, the response returns the user ID, username, name, numeric `access_level`,
the matching `access_level_name` (for example, `Maintainer`), and the membership `expires_at` date.
Members who were invited by email but have not accepted their invitation yet are not returned.

Each call returns a single page of results.
If more pages exist, the response `metadata` includes an `end_cursor` you can pass as `after` to fetch the next page.

Example:

```plaintext
Who are the maintainers of gitlab-org/gitlab?
```

## `accept_merge_request`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/617968) in GitLab 19.4.

{{< /history >}}

Merges a merge request, or schedules it to merge automatically. Without `strategy`, the merge
starts immediately and completes asynchronously. With `strategy`, auto-merge is armed and the
merge request merges once its checks pass. To approve a merge request instead, use the
`save_merge_request_review` tool.

Calls against a merge request that is already merged succeed with status `already_merged`,
and calls with a `strategy` against a merge request that is already scheduled succeed with
status `already_scheduled`.

| Parameter                     | Type    | Required | Description |
|-------------------------------|---------|----------|-------------|
| `url`                         | string  | No       | GitLab URL of the merge request. Provide this, or `project_id` and `merge_request_iid`. |
| `project_id`                  | string  | No       | ID or path of the project. Required if `url` is missing. |
| `merge_request_iid`           | integer | No       | Internal ID of the merge request. Required if `url` is missing. |
| `sha`                         | string  | Yes      | Head SHA guard. When it no longer matches the merge request head, the merge is refused. Pass the `diff_head_sha` returned by `get_merge_request`. |
| `strategy`                    | string  | No       | Auto-merge strategy, for example `merge_when_checks_pass`. When given, arms auto-merge instead of merging immediately. |
| `squash`                      | boolean | No       | Squash the commits into a single commit on merge. |
| `commit_message`              | string  | No       | Custom merge commit message. |
| `squash_commit_message`       | string  | No       | Custom squash commit message. Applies when `squash` is `true`. |
| `should_remove_source_branch` | boolean | No       | Remove the source branch after merging. |

Example:

```plaintext
Merge merge request 42 in project gitlab-org/gitlab once its checks pass, and remove the source branch
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

## `get_repository_file`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248744) in GitLab 19.3.

{{< /history >}}

Retrieves the contents of a single file from a repository at a specific ref.

Content comes from the repository, not from your local filesystem.
The file is returned as committed at `ref`, so uncommitted changes in a local checkout are not included.

| Parameter    | Type    | Required | Description |
|--------------|---------|----------|-------------|
| `url`        | string  | No       | URL of the file, for example `https://gitlab.example.com/my-group/my-project/-/blob/main/app/models/user.rb`. Provide this, or `project_id`, `file_path`, and `ref`. |
| `project_id` | string  | No       | ID or full path of the project. Required if `url` is not provided. |
| `file_path`  | string  | No       | Path of the file relative to the repository root. Required if `url` is not provided. |
| `ref`        | string  | No       | Branch name, tag name, or commit SHA. Use `HEAD` for the default branch. Required if `url` is not provided. |
| `offset`     | integer | No       | Zero-indexed line to start reading from. Default is `0`. |
| `limit`      | integer | No       | Maximum number of lines to return. Default and maximum are `2000`. |

The response contains a `metadata` object with `total_lines`, `returned_lines`, `truncated`, and `size_bytes`.
When the response covers only part of the file, `system_instruction` states the `offset` to use in the next call.

This tool returns text only.
Binary files and files stored in Git LFS return an error.
Files that a project excludes from GitLab Duo context also return an error.

Example:

```plaintext
Show me app/models/user.rb from the main branch of my-group/my-project
```

## `get_commit`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/605874) in GitLab 19.3.

{{< /history >}}

Retrieves a single commit's metadata, and optionally its diff or notes.

| Parameter     | Type    | Required | Description |
|---------------|---------|----------|-------------|
| `url`         | string  | No       | URL of the GitLab commit. Required if `project_id` and `commit_sha` are not provided. |
| `project_id`  | string  | No       | ID or URL-encoded path of the project. Required if `url` is not provided. |
| `commit_sha`  | string  | No       | Commit to look up. Accepts a full or short SHA, branch name, or tag name. Required if `url` is not provided. |
| `include`     | array   | No       | Associated facet to fetch inline, one per call (`diff` or `notes`). Base metadata is always returned. |
| `diff_detail` | string  | No       | Level of detail in the commit diff. Applies only when `include` contains `diff`. Can be either `stats` or `full_patch`. Default is `stats`. |
| `notes_after` | string  | No       | Token to fetch the next page of notes. Applies only when `include` contains `notes`. |
| `notes_first` | integer | No       | Number of notes to return per page (maximum 100). Applies only when `include` contains `notes`. |

With `diff_detail` set to `stats`, the diff facet returns per-file and summary line counts.
With `full_patch`, it returns the patch text.

Example:

```plaintext
Show me commit abc123 in gitlab-org/gitlab with its diff stats
```

## `list_releases`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/618494) in GitLab 19.4.

{{< /history >}}

Lists releases in a GitLab project, most recently released first.

| Parameter    | Type    | Required | Description |
|--------------|---------|----------|-------------|
| `url`        | string  | No       | GitLab URL of the project. Required if `project_id` is not provided. |
| `project_id` | string  | No       | ID or full path of the project. Required if `url` is not provided. |
| `page`       | integer | No       | Page number to retrieve. Default is `1`. |
| `per_page`   | integer | No       | Releases to return per page. Default is `20`, maximum is `100`. |
| `state`      | string  | No       | Filter by release state: `released`, `upcoming`, or `all`. Default is `released`. |

Provide exactly one of `url` or `project_id`.

Each entry returns release metadata only: `tag_name`, `name`, `released_at`, `upcoming`, and
`assets`. `assets` holds a `count` of the release's asset links and up to five of those `links`.
When a release has more than five, `count` reports the real total. Source archives are excluded,
because they are derivable from the tag.

The response also carries a `metadata` object with `page`, `per_page`, and `has_more`. Use
`has_more` to decide whether to request the next page.

Release notes are intentionally not returned in this response.

A release with a future `released_at` is scheduled rather than published, and sorts ahead of
published releases. Use `state` to control which you get. Scheduled releases carry `upcoming` set
to `true`.

To read the commit a release is built on, pass its `tag_name` to the `get_commit` tool. To
download an asset, use the `url` from `assets.links`.

Example:

```plaintext
List the most recent releases for project gitlab-org/gitlab
```

## `get_pipeline`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/605853) in GitLab 19.3.

{{< /history >}}

Retrieves a pipeline, and optionally its jobs, downstream pipelines, or bridge (trigger) jobs.

| Parameter     | Type    | Required | Description |
|---------------|---------|----------|-------------|
| `id`          | string  | Yes      | ID or full path of the project. |
| `pipeline_id` | integer | Yes      | ID of the pipeline. |
| `include`     | array   | No       | Facet to include alongside the pipeline, one per call: `jobs`, `downstream_pipelines`, or `bridge_jobs`. |
| `job_status`  | string  | No       | Filters the `jobs` facet by status (for example, `failed`). Only applies when `include` is `jobs`. |
| `first`       | integer | No       | Number of items to return for the selected `include` facet. Default is `20`, maximum is `100`. |
| `after`       | string  | No       | Cursor for forward pagination of the selected `include` facet. Use `page_info.end_cursor` from a previous response. |

A bridge job's `downstream_pipeline` is omitted (`null`) both when the trigger job hasn't
triggered a downstream pipeline yet, and when you don't have access to that pipeline.

Each downstream pipeline includes a `project_full_path`, because a downstream pipeline can belong to
a different project. Use that value as the `id` of a follow-up call.

Examples:

- Get a pipeline:

  ```plaintext
  Get the status of pipeline 12345 in project gitlab-org/gitlab
  ```

- Get a pipeline's failed jobs:

  ```plaintext
  Show me the failed jobs in pipeline 12345 for project gitlab-org/gitlab
  ```

- Get a pipeline's downstream pipelines:

  ```plaintext
  Show me the downstream pipelines triggered by pipeline 12345 in project gitlab-org/gitlab
  ```

## `get_pipeline_jobs`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055) in GitLab 18.4.

{{< /history >}}

Retrieves the jobs for a specific GitLab CI/CD pipeline. To get jobs alongside the rest of the
pipeline's data in a single call, use the `get_pipeline` tool with `include: jobs` instead.

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

## `get_job`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/605856) in GitLab 19.3.
- [Renamed](https://gitlab.com/gitlab-org/gitlab/-/work_items/605856) from `get_job_log` in GitLab 19.3. `get_job_log` continues to work as an alias and always returns the `log` facet, capped at `byte_limit`.

{{< /history >}}

Gets a CI/CD job's metadata, and optionally its trace/log.

| Parameter     | Type    | Required | Description |
|---------------|---------|----------|-------------|
| `id`          | string  | Yes      | ID or full path of the project. |
| `job_id`      | integer | Yes      | ID of the job. |
| `include`     | array   | No       | Facet to include alongside the job, one per call: `log`. |
| `byte_offset` | integer | No       | Byte offset to start reading the job's log from. Only applies when `include` is `log`. Default is `0`. |
| `byte_limit`  | integer | No       | Maximum number of bytes of the job's log to return. Only applies when `include` is `log`. Default and maximum is `512000`. |

When the log is longer than `byte_limit`, the response reports the total size and tells you the
`byte_offset` to use for the next window.

Examples:

- Get a job's metadata:

  ```plaintext
  Get the status of job 88 in project gitlab-org/gitlab
  ```

- Get a job's log:

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

## `save_pipeline`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/605855) in GitLab 19.3.
- `update` action [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/619469) in GitLab 19.4.

{{< /history >}}

Runs, retries, cancels, or renames a CI/CD pipeline in a GitLab project. To delete a
pipeline, use the `manage_pipeline` tool instead. To list pipelines, use the
`list_pipelines` tool instead.

| Parameter     | Type    | Required    | Description |
|---------------|---------|-------------|-------------|
| `url`         | string  | No          | GitLab URL of the project. Used only to create a pipeline. Provide this, or `project_id`. |
| `project_id`  | string  | No          | ID or full path of the project. Used only to create a pipeline. Provide this, or `url`. |
| `pipeline_id` | integer | No          | ID of an existing pipeline to target. When set, requires `action`. Omit to create a new pipeline. |
| `action`      | string  | No          | Lifecycle action to perform on `pipeline_id`: `retry`, `cancel`, or `update`. Required when `pipeline_id` is set. |
| `ref`         | string  | No          | Branch or tag name. Required to create a pipeline (when `pipeline_id` is absent). |
| `name`        | string  | No          | New pipeline name. Required for `action: "update"`. |
| `variables`   | array   | No          | Pipeline variables in array format (`[{key, value, variable_type}]`). |
| `inputs`      | hash    | No          | Pipeline input parameters as key-value pairs. |

Examples:

- Create a pipeline:

  ```plaintext
  Create a pipeline on the main branch for project gitlab-org/gitlab
  ```

- Retry a pipeline:

  ```plaintext
  Retry failed jobs in pipeline 12345 for project gitlab-org/gitlab
  ```

- Cancel a pipeline:

  ```plaintext
  Cancel pipeline 12345 in project gitlab-org/gitlab
  ```

- Rename a pipeline:

  ```plaintext
  Rename pipeline 12345 to "Nightly security scan" in project gitlab-org/gitlab
  ```

## `manage_pipeline`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/583826) in GitLab 18.10.
- [Removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/247806) the `list` action in favor of the `list_pipelines` tool in GitLab 19.3.
- [Removed](https://gitlab.com/gitlab-org/gitlab/-/work_items/605855) the `create`, `retry`, and `cancel` actions in favor of the `save_pipeline` tool in GitLab 19.3.

{{< /history >}}

Updates pipeline metadata or deletes a pipeline in a GitLab project. To create, retry, or cancel a
pipeline, use the `save_pipeline` tool instead. To list pipelines, use the `list_pipelines` tool
instead.

| Parameter     | Type    | Required    | Description |
|---------------|---------|-------------|-------------|
| `id`          | string  | Yes         | ID or URL-encoded path of the project. |
| `pipeline_id` | integer | Yes         | ID of the pipeline. If only this parameter is set, deletes a pipeline and all related data. |
| `name`        | string  | No          | Name of the pipeline. If this parameter and `pipeline_id` are set, updates the pipeline metadata. |

Examples:

- Update a pipeline:

  ```plaintext
  Rename pipeline 12345 to "My deploy pipeline" in project gitlab-org/gitlab
  ```

- Delete a pipeline:

  ```plaintext
  Delete pipeline 12345 in project gitlab-org/gitlab
  ```

## `get_work_item`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/605882) in GitLab 19.4.

{{< /history >}}

Retrieves a single work item (issue, epic, task, incident, objective, or key result) with its
type, dates, assignees, labels, milestone, and parent. Optionally includes its notes or the
merge requests related to it. Widgets the work item type does not support are omitted.

| Parameter                       | Type    | Required | Description |
|---------------------------------|---------|----------|-------------|
| `url`                           | string  | No       | GitLab URL of the work item (a `/-/work_items/`, `/-/issues/`, or `/-/epics/` URL). Provide this, or `work_item_iid` with `group_id` or `project_id`. |
| `group_id`                      | string  | No       | ID or path of the group. Required if `url` and `project_id` are missing. |
| `project_id`                    | string  | No       | ID or path of the project. Required if `url` and `group_id` are missing. |
| `work_item_iid`                 | integer | No       | Internal ID of the work item. Required if `url` is missing. |
| `include`                       | array   | No       | Associated data to return. One of `notes` or `related_merge_requests`, one facet per call. |
| `related_merge_requests_first`  | integer | No       | Number of related merge requests to return. Default 20, maximum 100. |
| `related_merge_requests_after`  | string  | No       | Cursor for forward pagination of related merge requests. |
| `mr_page_size`                  | integer | No       | Deprecated: use `related_merge_requests_first` instead. |
| `mr_pagination_cursor`          | string  | No       | Deprecated: use `related_merge_requests_after` instead. |

The `notes` facet returns the first 100 notes. Use `get_workitem_notes` for full note
pagination. The `related_merge_requests` facet is empty for group-level work items such
as epics.

Example:

```plaintext
Get issue 42 in project gitlab-org/gitlab with its related merge requests
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

## `save_work_item`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/605852) in GitLab 19.4.
- `labels`, `add_labels`, `remove_labels`, `milestone_id`, and `milestone` parameters [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/622711) in GitLab 19.4.

{{< /history >}}

Creates or updates a GitLab work item, such as an issue, task, or epic. Omit `work_item_iid`
to create a new work item. Provide `work_item_iid` or a work item URL to update an existing
one. Send only the fields you intend to set, and omit the rest. The tool names
`create_work_item` and `update_work_item` are aliases for this tool.

| Parameter          | Type              | Required | Description |
|--------------------|-------------------|----------|-------------|
| `url`              | string            | No       | GitLab URL for the project, group, or work item. Provide exactly one of `url`, `project_id`, or `group_id`. |
| `group_id`         | string            | No       | ID or path of the group. Required if `url` and `project_id` are missing. |
| `project_id`       | string            | No       | ID or path of the project. Required if `url` and `group_id` are missing. |
| `work_item_iid`    | integer           | No       | Positive internal ID of the work item to update. Omit to create a new work item. |
| `title`            | string            | No       | Title of the work item. Required when creating a work item. |
| `type_name`        | string            | No       | Work item type name, for example `Issue`, `Task`, or `Epic`. Required when creating a work item. Valid types depend on the namespace and license. |
| `description`      | string            | No       | Description in GitLab Flavored Markdown. Maximum 1,048,576 characters. |
| `assignee_ids`     | array of integers | No       | User IDs to assign to the work item. Maximum 100 items. |
| `label_ids`        | array of strings  | No       | Label IDs or global IDs. Create only; on update use `add_label_ids` or `remove_label_ids`. Maximum 100 items. |
| `labels`           | array of strings  | No       | Names of the labels to set, resolved in the project or group and its ancestor groups. Create only; on update use `add_labels` or `remove_labels`. Maximum 100 items. |
| `add_label_ids`    | array of strings  | No       | Update only. Label IDs or global IDs to add. Maximum 100 items. |
| `add_labels`       | array of strings  | No       | Update only. Names of the labels to add. Maximum 100 items. |
| `remove_label_ids` | array of strings  | No       | Update only. Label IDs or global IDs to remove. Maximum 100 items. |
| `remove_labels`    | array of strings  | No       | Update only. Names of the labels to remove. Maximum 100 items. |
| `milestone_id`     | string            | No       | ID or global ID of the milestone to assign, validated against the project or group and its ancestor groups. Wins over `milestone` when both are given. |
| `milestone`        | string            | No       | Title of the milestone to assign, resolved among the milestones of the project or group and its ancestor groups. |
| `confidential`     | boolean           | No       | Sets the work item confidentiality. |
| `start_date`       | string            | No       | Start date, in `YYYY-MM-DD` format. |
| `due_date`         | string            | No       | Due date, in `YYYY-MM-DD` format. |
| `state`            | string            | No       | Update only. `closed` closes the work item, `opened` reopens it. |
| `parent_id`        | string            | No       | Global ID or numeric ID of the parent work item. |
| `todo_action`      | string            | No       | Update only. `add` adds a to-do for the current user, `mark_as_done` marks to-dos as done. |
| `todo_id`          | string            | No       | Update only. Global ID or numeric ID of the to-do. Omit to update all to-dos on the work item. |
| `health_status`    | string            | No       | Health status. One of `onTrack`, `needsAttention`, or `atRisk`. Ultimate only. |
| `weight`           | integer           | No       | Weight of the work item. Must be 0 or greater. Premium and Ultimate only. |
| `clear_weight`     | boolean           | No       | Update only. Removes the weight. Takes precedence over `weight`. Premium and Ultimate only. |
| `status_id`        | string            | No       | Global ID of the status to set. Premium and Ultimate only. |
| `is_fixed`         | boolean           | No       | Whether start and due dates are fixed. When `false`, dates roll up from child items and `start_date` and `due_date` are ignored. Premium and Ultimate only. |
| `agent_plan`       | string            | No       | Markdown content of the agent plan. Ultimate only. Requires the workplan feature. |
| `readiness_score`  | integer           | No       | Readiness score of the agent plan, from 0 to 100. Ultimate only. Requires the `workplan_score` feature flag. Returns an error when the flag is disabled. |

Example:

```plaintext
Create a task "Update the onboarding guide" in project gitlab-org/gitlab and assign it to me
```

## `list_work_items`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/605850) in GitLab 19.4.

{{< /history >}}

Lists or searches work items (issues, incidents, test cases, requirements, tasks, tickets,
objectives, key results, epics) in a group or project. Group scope includes work items of
descendant projects and subgroups. Each result contains only the ID, IID, title, state, web URL,
full reference, created and updated timestamps, and work item type, with cursor pagination.
Use `get_work_item` to read one work item in depth.

| Parameter               | Type    | Required | Description |
|-------------------------|---------|----------|-------------|
| `url`                   | string  | No       | GitLab URL for the project or group. Provide exactly one of `url`, `group_id`, or `project_id`. |
| `group_id`              | string  | No       | ID or path of the group. Required if `url` and `project_id` are missing. |
| `project_id`            | string  | No       | ID or path of the project. Required if `url` and `group_id` are missing. |
| `state`                 | string  | No       | Filter by state: `opened`, `closed`, or `all` (default). |
| `search`                | string  | No       | Free-text search in title and description. |
| `author_username`       | string  | No       | Username of the author. |
| `assignee_usernames`    | array   | No       | Usernames of assignees. A work item must match all of them. Maximum 100 values. |
| `label_name`            | array   | No       | Label names. A work item must have all of them. Maximum 100 values. |
| `milestone_title`       | array   | No       | Milestone titles. Cannot be combined with `milestone_wildcard_id`. Maximum 100 values. |
| `milestone_wildcard_id` | string  | No       | `NONE`, `ANY`, `STARTED`, or `UPCOMING`. Cannot be combined with `milestone_title`. |
| `types`                 | array   | No       | Work item types to include, for example `["ISSUE", "TASK"]`. |
| `created_after`         | string  | No       | Created after this time (ISO 8601; date-only means start of day, offsets honored). |
| `created_before`        | string  | No       | Created before this time (ISO 8601; date-only means start of day, offsets honored). |
| `updated_after`         | string  | No       | Updated after this time (ISO 8601; date-only means start of day, offsets honored). |
| `updated_before`        | string  | No       | Updated before this time (ISO 8601; date-only means start of day, offsets honored). |
| `due_after`             | string  | No       | Due after this time (ISO 8601; date-only means start of day, offsets honored). |
| `due_before`            | string  | No       | Due before this time (ISO 8601; date-only means start of day, offsets honored). |
| `sort`                  | string  | No       | Sort order, for example `UPDATED_DESC`. Default `CREATED_DESC`. |
| `first`                 | integer | No       | Number of work items to return. Default 20, maximum 100. |
| `after`                 | string  | No       | Cursor for forward pagination. |
| `health_status_filter`  | string  | No       | Ultimate only. `onTrack`, `needsAttention`, or `atRisk`. |
| `status`                | object  | No       | Ultimate only. Filter by custom status name, for example `{"name": "In progress"}`. |

Example:

```plaintext
List my open tasks in the gitlab-org group updated this month.
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

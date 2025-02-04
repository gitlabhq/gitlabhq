---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Custom queries in the VS Code extension
---

The **GitLab Workflow** extension adds a [sidebar](_index.md#view-issues-and-merge-requests)
to VS Code. This sidebar displays default search queries for each of your projects:

- Issues assigned to me
- Issues created by me
- Merge requests assigned to me
- Merge requests created by me
- Merge requests I'm reviewing

In addition to the default queries, you can [create custom queries](#create-a-custom-query).

## View search query results in VS Code

Prerequisites:

- You're a member of a GitLab project.
- You've [installed the extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow).
- You've signed in to your GitLab instance, as described in [Setup](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/tree/main/#setup).

To see search results from your project:

1. On the left vertical menu bar, select **GitLab Workflow** (**{tanuki}**) to display the extension sidebar.
1. On the sidebar, expand **Issues and merge requests**.
1. Select a project to view its queries, then select the query you want to run.
1. Below the query title, select the search result you want to see.
1. If your search result is a merge request, select what you want to view in VS Code:
   - **Overview**: the description, status, and any comments on this merge request.
   - The **filenames** of all files changed in this merge request. Select a file to view a diff
     of its changes.
1. If your search result is an issue, select it to view its description, history, and comments in VS Code.

## Create a custom query

Any custom queries you define override the default queries shown in the
[VS Code sidebar](_index.md#view-issues-and-merge-requests),
under **Issues and Merge requests**.

To override the extension's default queries and replace them with your own:

1. In VS Code, on the top bar, go to **Code > Preferences > Settings**.
1. On the top right corner, select **Open Settings (JSON)** to edit your `settings.json` file.
1. In the file, define `gitlab.customQueries`, like in this example. Each query should be an entry
   in the `gitlab.customQueries` JSON array:

   ```json
   {
     "gitlab.customQueries": [
       {
         "name": "Issues assigned to me",
         "type": "issues",
         "scope": "assigned_to_me",
         "noItemText": "No issues assigned to you.",
         "state": "opened"
       }
     ]
   }
   ```

1. Optional. When you customize `gitlab.customQueries`, your definition overrides all default queries.
   To restore any of the default queries, copy them from the `default` array in the extension's
   [`desktop.package.json` file](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/8e4350232154fe5bf0ef8a6c0765b2eac0496dc7/desktop.package.json#L955-998).
1. Save your changes.

### Supported parameters for all queries

Not all item types support all parameters. These parameters apply to all query types:

| Parameter    | Required | Default           | Definition |
|--------------|----------|-------------------|------------|
| `name`       | **{check-circle}** Yes | not applicable               | The label to show in the GitLab panel. |
| `noItemText` | **{dotted-circle}** No       | `No items found.` | The text to show if the query returns no items. |
| `type`       | **{dotted-circle}** No       | `merge_requests`  | Which item types to return. Possible values: `issues`, `merge_requests`, `epics`, `snippets`, `vulnerabilities`. Snippets [don't support](../../api/project_snippets.md) any other filters. Epics are available only on GitLab Premium and Ultimate.|

### Supported parameters for issue, epic, and merge request queries

| Parameter          | Required               | Default      | Definition |
|--------------------|------------------------|--------------|------------|
| `assignee`         | **{dotted-circle}** No | not applicable          | Return items assigned to the given username. `None` returns unassigned GitLab items. `Any` returns GitLab items with an assignee. Not available for epics and vulnerabilities. |
| `author`           | **{dotted-circle}** No | not applicable          | Return items created by the given username. |
| `confidential`     | **{dotted-circle}** No | not applicable          | Filter confidential or public issues. Available only for issues. |
| `createdAfter`     | **{dotted-circle}** No | not applicable          | Return items created after the given date. |
| `createdBefore`    | **{dotted-circle}** No | not applicable          | Return items created before the given date. |
| `draft`            | **{dotted-circle}** No | `no`         | Filter merge requests against their draft status: `yes` returns only merge requests in [draft status](../../user/project/merge_requests/drafts.md), `no` returns only merge requests not in draft status. Available only for merge requests. |
| `excludeAssignee`  | **{dotted-circle}** No | not applicable          | Return items not assigned to the given username. Available only for issues. For the current user, set to `<current_user>`. |
| `excludeAuthor`    | **{dotted-circle}** No | not applicable          | Return items not created by the given username. Available only for issues. For the current user, set to `<current_user>`. |
| `excludeLabels`    | **{dotted-circle}** No | `[]`         | Array of label names. Available only for issues. Items returned have none of the labels in the array. Predefined names are case-insensitive. |
| `excludeMilestone` | **{dotted-circle}** No | not applicable          | The milestone title to exclude. Available only for issues. |
| `excludeSearch`    | **{dotted-circle}** No | not applicable          | Search GitLab items that doesn't have the search key in their title or description. Works only with issues. |
| `labels`           | **{dotted-circle}** No | `[]`         | Array of label names. Items returned have all labels in the array. `None` returns items with no labels. `Any` returns items with at least one label. Predefined names are case-insensitive. |
| `maxResults`       | **{dotted-circle}** No | 20           | The number of results to show. |
| `milestone`        | **{dotted-circle}** No | not applicable          | The milestone title. `None` lists all items with no milestone. `Any` lists all items with an assigned milestone. Not available for epics and vulnerabilities. |
| `orderBy`          | **{dotted-circle}** No | `created_at` | Return entities ordered by the selected value. Possible values: `created_at`, `updated_at`, `priority`, `due_date`, `relative_position`, `label_priority`, `milestone_due`, `popularity`, `weight`. Some values are specific to issues, and some to merge requests. For more information, see [List merge requests](../../api/merge_requests.md#list-merge-requests). |
| `reviewer`         | **{dotted-circle}** No | not applicable          | Return merge requests assigned for review to this username. For the current user, set to `<current_user>`. `None` returns items without a reviewer. `Any` returns items with a reviewer. |
| `scope`            | **{dotted-circle}** No | `all`        | Return GitLab items for the given scope. Not applicable for epics. Possible values: `assigned_to_me`, `created_by_me`, `all`. |
| `search`           | **{dotted-circle}** No | not applicable          | Search GitLab items against their title and description. |
| `searchIn`         | **{dotted-circle}** No | `all`        | Change the scope of the `excludeSearch` search attribute. Possible values: `all`, `title`, `description`. Works only with issues. |
| `sort`             | **{dotted-circle}** No | `desc`       | Return issues sorted in ascending or descending order. Possible values: `asc`, `desc`. |
| `state`            | **{dotted-circle}** No | `opened`     | Return all issues, or only those matching a particular state. Possible values: `all`, `opened`, `closed`. |
| `updatedAfter`     | **{dotted-circle}** No | not applicable          | Return items updated after the given date. |
| `updatedBefore`    | **{dotted-circle}** No | not applicable          | Return items updated before the given date. |

### Supported parameters for vulnerability report queries

Vulnerability reports don't share
[any common query parameters](../../api/vulnerability_findings.md)
with other entry types. Each parameter listed in this table works with vulnerability reports only:

| Parameter          | Required               | Default        | Definition |
|--------------------|------------------------|----------------|------------|
| `confidenceLevels` | **{dotted-circle}** No | `all`          | Returns vulnerabilities belonging to specified confidence levels. Possible values: `undefined`, `ignore`, `unknown`, `experimental`, `low`, `medium`, `high`, `confirmed`. |
| `reportTypes`      | **{dotted-circle}** No | Not applicable | Returns vulnerabilities belonging to specified report types. Possible values: `sast`, `dast`, `dependency_scanning`, `container_scanning`. |
| `scope`            | **{dotted-circle}** No | `dismissed`    | Returns vulnerability findings for the given scope. Possible values: `all`, `dismissed`. For more information, see the [Vulnerability findings API](../../api/vulnerability_findings.md). |
| `severityLevels`   | **{dotted-circle}** No | `all`          | Returns vulnerabilities belonging to specified severity levels. Possible values: `undefined`, `info`, `unknown`, `low`, `medium`, `high`, `critical`. |

---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Custom queries in the VS Code extension
---

The GitLab for VS Code extension adds a **GitLab** ({{< icon name="tanuki" >}}) panel to VS Code
that you can use to [work with your projects](projects.md).

By default, the **Issues and merge requests** section of the panel displays the results of these
search queries:

- Issues assigned to me
- Issues created by me
- Merge requests assigned to me
- Merge requests created by me
- Merge requests I'm reviewing

Use custom queries to customize this section and display information that matters to you.

## Create a custom query

Custom queries override the default queries shown in the **GitLab** ({{< icon name="tanuki" >}})
panel under **Issues and merge requests**.

To use custom queries for the panel:

1. In VS Code, open the **Settings** editor:
   - For macOS, press <kbd>Command</kbd>+<kbd>,</kbd>.
   - For Windows or Linux, press <kbd>Control</kbd>+<kbd>,</kbd>.
1. In the upper-right corner, select **Open Settings (JSON)** to edit your `settings.json` file.
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

1. Optional. To maintain any of the default queries, copy them from the `default`
   array in the extension's [`desktop.package.json` file](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/8e4350232154fe5bf0ef8a6c0765b2eac0496dc7/desktop.package.json#L955-998) and add them to the
   `gitlab.customQueries` array as additional custom queries.
1. Save your changes.

### Supported parameters for all queries

These parameters apply to all query types:

| Parameter    | Required    | Default           | Definition |
|--------------|-------------|-------------------|------------|
| `name`       | {{< yes >}} | None              | Specifies the label to display in the **GitLab** panel. |
| `noItemText` | {{< no >}}  | `No items found.` | Specifies the text to display if the query returns zero items. |
| `type`       | {{< no >}}  | `merge_requests`  | Specifies the item types to return. Possible values: `issues`, `merge_requests`, `epics`, `snippets`, `vulnerabilities`. Snippets [do not support](../../api/project_snippets.md) any other filters. Epics are available only on GitLab Premium and Ultimate. |

### Supported parameters for issue, epic, and merge request queries

All of these parameters are optional.

| Parameter          | Default        | Definition |
|--------------------|----------------|------------|
| `assignee`         | None           | Returns items assigned to the given username. `None` returns unassigned GitLab items. `Any` returns GitLab items with an assignee. Not available for epics and vulnerabilities. |
| `author`           | None           | Returns items created by the given username. |
| `confidential`     | None           | Returns confidential or public issues. Available only for issues. |
| `createdAfter`     | None           | Returns items created after the given date. |
| `createdBefore`    | None           | Returns items created before the given date. |
| `draft`            | `no`           | Returns merge requests filtered by draft status: `yes` returns only merge requests in [draft status](../../user/project/merge_requests/drafts.md), `no` returns only merge requests not in draft status. Available only for merge requests. |
| `excludeAssignee`  | None           | Returns items not assigned to the given username. Available only for issues. For the current user, set to `<current_user>`. |
| `excludeAuthor`    | None           | Returns items not created by the given username. Available only for issues. For the current user, set to `<current_user>`. |
| `excludeLabels`    | `[]`           | Returns items that have none of the labels in the given array. Available only for issues. Predefined names are case-insensitive. |
| `excludeMilestone` | None           | Returns items that exclude the given milestone title. Available only for issues. |
| `excludeSearch`    | None           | Returns items without the search key in their title or description. Works only with issues. |
| `labels`           | `[]`           | Returns items that have all labels in the given array. `None` returns items with no labels. `Any` returns items with at least one label. Predefined names are case-insensitive. |
| `maxResults`       | 20             | Returns up to this number of results. |
| `milestone`        | None           | Returns items matching the given milestone title. `None` returns all items with no milestone. `Any` returns all items with an assigned milestone. Not available for epics and vulnerabilities. |
| `orderBy`          | `created_at`   | Returns items ordered by the selected value. Possible values: `created_at`, `updated_at`, `priority`, `due_date`, `relative_position`, `label_priority`, `milestone_due`, `popularity`, `weight`. Some values are specific to issues, and some to merge requests. For more information, see [list merge requests](../../api/merge_requests.md#list-merge-requests). |
| `reviewer`         | None           | Returns merge requests with the given username assigned as the reviewer. For the current user, set to `<current_user>`. `None` returns items without a reviewer. `Any` returns items with a reviewer. |
| `scope`            | `all`          | Returns items for the given scope. Not applicable for epics. Possible values: `assigned_to_me`, `created_by_me`, `all`. |
| `search`           | None           | Returns items with the given search term in their title and description. |
| `searchIn`         | `all`          | Returns results with the `excludeSearch` attribute scoped to the given value. Possible values: `all`, `title`, `description`. Works only with issues. |
| `sort`             | `desc`         | Returns issues sorted in ascending or descending order. Possible values: `asc`, `desc`. |
| `state`            | `opened`       | Returns all issues or only those matching a particular state. Possible values: `all`, `opened`, `closed`. |
| `updatedAfter`     | None           | Returns items updated after the given date. |
| `updatedBefore`    | None           | Returns items updated before the given date. |

### Supported parameters for vulnerability report queries

Vulnerability reports don't share [any common query parameters](../../api/vulnerability_findings.md)
with other entry types. Each parameter listed in this table works with vulnerability reports only,
and all parameters are optional:

| Parameter          | Default        | Definition |
|--------------------|----------------|------------|
| `confidenceLevels` | `all`          | Returns vulnerabilities with the given confidence levels. Possible values: `undefined`, `ignore`, `unknown`, `experimental`, `low`, `medium`, `high`, `confirmed`. |
| `reportTypes`      | None           | Returns vulnerabilities with the given report types. Possible values: `sast`, `dast`, `dependency_scanning`, `container_scanning`. |
| `scope`            | `dismissed`    | Returns vulnerabilities for the given scope. Possible values: `all`, `dismissed`. For more information, see the [Vulnerability findings API](../../api/vulnerability_findings.md). |
| `severityLevels`   | `all`          | Returns vulnerabilities with the given severity levels. Possible values: `undefined`, `info`, `unknown`, `low`, `medium`, `high`, `critical`. |

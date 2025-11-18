---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Export issues to CSV
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- The `IID`, `Type`, `Start Date`, and `Parent IID` columns [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199945) in GitLab 18.4.

{{< /history >}}

You can export issues from GitLab to a plain-text CSV
([comma-separated values](https://en.wikipedia.org/wiki/Comma-separated_values))
file. The CSV file is attached to an email, and sent to your default
notification email address.

<!-- vale gitlab_base.Spelling = NO -->

CSV files can be used with any plotter or spreadsheet-based program, like
Microsoft Excel, OpenOffice Calc, or Google Sheets. Use a CSV list of issues to:

<!-- vale gitlab_base.Spelling = YES -->

- Create a snapshot of issues for offline analysis, or to share with other
  teams who might not be in GitLab.
- Create diagrams, graphs, and charts from the CSV data.
- Convert the data to other formats for auditing or sharing.
- Import the issues to a system outside of GitLab.
- Analyze long-term trends with multiple snapshots created over time.
- Use the long-term data to gather relevant feedback given in the issues, and
  improve your product based on real metrics.

## Select issues to export

You can export issues from individual projects, but not groups.

Prerequisites:

- You must have at least the Guest role.

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Plan** > **Issues**.
1. Above the list of issues, select **Search or filter results**.
1. In the dropdown list that appears, select the attributes to filter by.
   For more information about filter options, see
   [Filter the list of issues](managing_issues.md#filter-the-list-of-issues).
1. In the upper right, select **Actions** ({{< icon name="ellipsis_v" >}}) > **Export as CSV**.
1. In the dialog, verify that the email address is correct, then select **Export issues**.

All matching issues are exported, including those not shown on the first page.
The exported CSV does not contain attachments from issues.

## Format

The CSV file has this format:

- Sort is by title.
- Columns are delimited with commas.
- Fields are quoted with double quotes (`"`) if needed.
- Newline characters separate rows.

{{< alert type="note" >}}

For information about CSV parsing requirements that can affect how exported files display when viewed
in GitLab, see [CSV parsing considerations](../repository/files/csv.md#csv-parsing-considerations).

{{< /alert >}}

## Columns

The following columns are included in the CSV file.

| Column            | Description |
| ----------------- | ----------- |
| ID                | Issue `id`  |
| IID               | Issue `iid` |
| Title             | Issue `title` |
| Description       | Issue `description` |
| Type              | Issue `type` |
| URL               | A link to the issue on GitLab |
| State             | `Open` or `Closed` |
| Confidential      | `Yes` or `No` |
| Locked            | `Yes` or `No` |
| Milestone         | Title of the issue milestone |
| Labels            | Labels, separated by commas |
| Author            | Full name of the issue author |
| Author Username   | Username of the author, with the `@` symbol omitted |
| Assignee          | Full name of the issue assignee |
| Assignee Username | Username of the assignee, with the `@` symbol omitted |
| Created At (UTC)  | Formatted as `YYYY-MM-DD HH:MM:SS` |
| Updated At (UTC)  | Formatted as `YYYY-MM-DD HH:MM:SS` |
| Closed At (UTC)   | Formatted as `YYYY-MM-DD HH:MM:SS` |
| Due Date          | Formatted as `YYYY-MM-DD` |
| Start Date        | Formatted as `YYYY-MM-DD` |
| Parent ID         | ID of the parent |
| Parent IID        | IID of the parent |
| Parent Title      | Title of the parent |
| Time Estimate     | [Time estimate](../time_tracking.md#estimates) in seconds |
| Time Spent        | [Time spent](../time_tracking.md#time-spent) in seconds |
| Weight            | Issue weight |

## Troubleshooting

When working with exported issues, you might encounter the following issues.

### Size of export

Issues are sent as an email attachment, with a 15 MB export limit to ensure
successful delivery across a range of email providers. If you reach the limit,
narrow your search before export. For example, consider exporting open and
closed issues separately.

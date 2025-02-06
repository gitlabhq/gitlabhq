---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Export issues to CSV
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Minimum role to export issues [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) from Reporter to Planner in GitLab 17.7.

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

- You must have at least the Planner role.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Plan > Issues**.
1. Above the list of issues, select **Search or filter results**.
1. In the dropdown list that appears, select the attributes to filter by.
   For more information about filter options, see
   [Filter the list of issues](managing_issues.md#filter-the-list-of-issues).
1. In the upper right, select **Actions** (**{ellipsis_v}**) **> Export as CSV**.
1. In the dialog, verify that the email address is correct, then select **Export issues**.

All matching issues are exported, including those not shown on the first page.
The exported CSV does not contain attachments from issues.

## Format

The CSV file has this format:

- Sort is by title.
- Columns are delimited with commas.
- Fields are quoted with double quotes (`"`) if needed.
- Newline characters separate rows.

## Columns

The following columns are included in the CSV file.

| Column            | Description |
|-------------------|-------------|
| Title             | Issue `title` |
| Description       | Issue `description` |
| Issue ID          | Issue `iid` |
| URL               | A link to the issue on GitLab |
| State             | `Open` or `Closed` |
| Author            | Full name of the issue author |
| Author Username   | Username of the author, with the `@` symbol omitted |
| Assignee          | Full name of the issue assignee |
| Assignee Username | Username of the author, with the `@` symbol omitted |
| Confidential      | `Yes` or `No` |
| Locked            | `Yes` or `No` |
| Due Date          | Formatted as `YYYY-MM-DD` |
| Created At (UTC)  | Formatted as `YYYY-MM-DD HH:MM:SS` |
| Updated At (UTC)  | Formatted as `YYYY-MM-DD HH:MM:SS` |
| Closed At (UTC)   | Formatted as `YYYY-MM-DD HH:MM:SS` |
| Milestone         | Title of the issue milestone |
| Weight            | Issue weight |
| Labels            | Labels, separated by commas |
| Time Estimate     | [Time estimate](../time_tracking.md#estimates) in seconds |
| Time Spent        | [Time spent](../time_tracking.md#time-spent) in seconds |
| Epic ID           | ID of the parent epic |
| Epic Title        | Title of the parent epic |

## Troubleshooting

When working with exported issues, you might encounter the following issues.

### Size of export

Issues are sent as an email attachment, with a 15 MB export limit to ensure
successful delivery across a range of email providers. If you reach the limit,
narrow your search before export. For example, consider exporting open and
closed issues separately.

---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Importing issues from CSV
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Additionally [allowed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) for Planner role in GitLab 17.7.

You can import issues to a project by uploading a CSV file with the following columns:

| Name          | Required?              | Description                                      |
|:--------------|:-----------------------|:-------------------------------------------------|
| `title`       | **{check-circle}** Yes | Issue title.                                     |
| `description` | **{check-circle}** Yes | Issue description.                               |
| `due_date`    | **{dotted-circle}** No | Issue due date in `YYYY-MM-DD` format. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91317) in GitLab 15.2. |
| `milestone`   | **{dotted-circle}** No | Title of the issue milestone. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112204) in GitLab 16.7.         |

Data in other columns is not imported.

You can use the `description` field to embed [quick actions](../quick_actions.md) to add other data to the issue.
For example, labels, assignees, and milestones.

Alternatively, you can [move an issue](managing_issues.md#move-an-issue). Moving issues preserves more data.

The user uploading the CSV file is set as the author of the imported issues.

You must have the Planner role or at least the Developer role for a project to import issues.

## Prepare for the import

- Consider importing a test file containing only a few issues. There is no way to undo a large import without using the GitLab API.
- Ensure your CSV file meets the [file format](#csv-file-format) requirements.
- If your CSV includes the milestone header, ensure all unique milestones titles in the file already exist in the project or its parent groups.

## Import the file

To import issues:

1. Go to your project's **Issues** page.
1. Open the import feature, depending if the project has issues:
   - The project has existing issues: in the upper-right corner, next to **Bulk edit**, select **Actions** (**{ellipsis_v}**) **> Import CSV**.
   - The project has no issues: in the middle of the page, select **Import CSV**.
1. Select the file you want to import, and then select **Import issues**.

The file is processed in the background, and a notification email is sent
to you if any errors are detected or after the import is complete.

## CSV file format

To import issues, GitLab requires CSV files have a specific format:

| Element                | Format |
|------------------------|--------|
| header row             | CSV files must include the following headers: `title` and `description`. The case of the headers does not matter. |
| columns                | Data from columns outside of `title`, `description`, `due_date`, and `milestone` are not imported. |
| separators             | The column separator is detected from the header row. Supported separator characters are commas (`,`), semicolons (`;`), and tabs (`\t`). The row separator can be either `CRLF` or `LF`. |
| double-quote character | The double-quote (`"`) character is used to quote fields, enabling the use of the column separator in a field (see the third line in the sample CSV data below). To insert a double-quote (`"`) in a quoted field use two double-quote characters in succession (`""`). |
| data rows              | After the header row, following rows must use the same column order. The issue title is required, but the description is optional. |

If you have special characters (for example, `,` or `\n`) or multiple lines in a field (for example,
when using [quick actions](../quick_actions.md)), surround the characters with double quotes (`"`).

Also when using [quick actions](../quick_actions.md):

- Each action must be on a separate line.
- For quick actions like `/label` and `/milestone`, the label or milestone must already exist in the project.
- The user you assign the issue to must be a member of the project.

Sample CSV data:

```plaintext
title,description,due_date,milestone
My Issue Title,My Issue Description,2022-06-28
Another Title,"A description, with a comma",
"One More Title","One More Description",
An Issue with Quick Actions,"Hey can we change the frontend?

/assign @sjones
/label ~frontend ~documentation",
An issue with milestone,"My milestone is created",,v1.0
```

### File size

The limit depends on how your GitLab instance is hosted:

- Self-managed: Set by the configuration value of `Max Attachment Size` for the GitLab instance.
- GitLab SaaS: On GitLab.com, it's set to 10 MB.

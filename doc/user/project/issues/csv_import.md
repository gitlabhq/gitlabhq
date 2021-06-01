---
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Importing issues from CSV **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/23532) in GitLab 11.7.

Issues can be imported to a project by uploading a CSV file with the columns
`title` and `description`. Other columns are **not** imported. If you want to
retain columns such as labels and milestones, consider the [Move Issue feature](managing_issues.md#moving-issues).

The user uploading the CSV file is set as the author of the imported issues.

NOTE:
A permission level of [Developer](../../permissions.md), or higher, is required
to import issues.

## Prepare for the import

- Consider importing a test file containing only a few issues. There is no way to undo a large import without using the GitLab API.
- Ensure your CSV file meets the [file format](#csv-file-format) requirements.

## Import the file

To import issues:

1. Navigate to a project's Issues list page.
1. If existing issues are present, click the import icon at the top right, next to the **Edit issues** button.
1. For a project without any issues, click the button labeled **Import CSV** in the middle of the page.
1. Select the file and click the **Import issues** button.

The file is processed in the background and a notification email is sent
to you once the import is complete.

## CSV file format

When importing issues from a CSV file, it must be formatted in a certain way:

- **header row:** CSV files must include the following headers:
`title` and `description`. The case of the headers does not matter.
- **columns:** Data from columns beyond `title` and `description` are not imported.
- **separators:** The column separator is automatically detected from the header row.
  Supported separator characters are: commas (`,`), semicolons (`;`), and tabs (`\t`).
  The row separator can be either `CRLF` or `LF`.
- **double-quote character:** The double-quote (`"`) character is used to quote fields,
  enabling the use of the column separator within a field (see the third line in the
  sample CSV data below). To insert a double-quote (`"`) within a quoted
  field, use two double-quote characters in succession, i.e. `""`.
- **data rows:** After the header row, succeeding rows must follow the same column
  order. The issue title is required while the description is optional.

If you have special characters _within_ a field, (such as `\n` or `,`),
wrap the characters in double quotes.

Sample CSV data:

```plaintext
title,description
My Issue Title,My Issue Description
Another Title,"A description, with a comma"
"One More Title","One More Description"
```

### File size

The limit depends on the configuration value of Max Attachment Size for the GitLab instance.

For GitLab.com, it is set to 10 MB.

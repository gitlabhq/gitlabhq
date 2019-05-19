# Importing issues from CSV

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/23532) in GitLab 11.7.

Issues can be imported to a project by uploading a CSV file with the columns
`title` and `description`, in that order.

The user uploading the CSV file will be set as the author of the imported issues.

> **Note:** A permission level of `Developer` or higher is required to import issues.

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
to you once the import is completed.

## CSV file format

### Header row

CSV files must contain a header row where the first column header is `title` and the second is `description`.
If additional columns are present, they will be ignored.

### Column separator

The column separator is automatically detected from the header row.

Supported separator characters are: commas (`,`), semicolons (`;`), and tabs (`\t`).

### Row separator

Lines ending in either `CRLF` or `LF` are supported.

### Quote character

The double-quote (`"`) character is used to quote fields so you can use the column separator within a field. To insert
a double-quote (`"`) within a quoted field, use two double-quote characters in succession, i.e. `""`.

### Data rows

After the header row, succeeding rows must follow the same column order. The issue title is required while the
description is optional.

### File size

The limit depends on the configuration value of Max Attachment Size for the GitLab instance.

For GitLab.com, it is set to 10 MB.

## Sample data

```csv
title,description
My Issue Title,My Issue Description
Another Title,"A description, with a comma"
"One More Title","One More Description"
```

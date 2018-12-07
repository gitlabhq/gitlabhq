# Importing Issues from CSV

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/23532) in GitLab 11.7.

Issues can be imported by uploading a CSV file. The file will be processed in the background and a notification email
will be sent to you once the import is completed.

> **Note:** A permission level of `Developer` or higher is required to import issues.

## CSV File Format

### Header row

CSV files must contain a header row with at least two columns: `title` and `description`, in that order.

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

The user uploading the CSV file will be set as the author of the imported issues.

## Sample Data

```csv
title,description
My Issue Title,My Issue Description
Another Title,"A description, with a comma"
"One More Title","One More Description"
```

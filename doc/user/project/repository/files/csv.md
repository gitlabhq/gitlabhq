---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: How comma-separated values (CSV) files display in GitLab projects.
title: CSV files
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

A comma-separated values (CSV) file is a delimited text file that uses a comma to separate values.
Each line of the file is a data record. Each record consists of one or more fields, separated by
commas. The use of the comma as a field separator is the source of the name for this file format.
A CSV file typically stores tabular data (numbers and text) in plain text, in which case each line
has the same number of fields.

The CSV file format is not fully standardized. Other characters can be used as column delimiters.
Fields may or may not be surrounded to escape special characters.

When added to a repository, files with a `.csv` extension are rendered as a table when viewed in
GitLab:

![CSV file rendered as a table](img/csv_as_table_v17_10.png)

## CSV parsing considerations

GitLab uses the [Papa Parse](https://github.com/mholt/PapaParse/) library to parse CSV files.
This library follows [RFC4180](https://datatracker.ietf.org/doc/html/rfc4180) and has strict formatting requirements that can cause parsing issues with certain CSV formats.

For example:

- Spacing around comma (`,`) separators and double quotes (`"`) can cause parsing errors.
- Fields containing both commas and double quotes can cause the parser to misidentify field boundaries.

The following format causes parsing errors:

```plaintext
"field1", "field2", "field3"
```

The following format parses successfully:

```plaintext
"field1","field2","field3"
```

If your CSV file doesn't display correctly in GitLab:

- If fields are enclosed in double quotes (`"`), ensure the double quotes and comma (`,`) separators are immediately adjacent, with no spaces in between.
- Enclose all fields that contain special characters in double quotes (`"`).
- Test how the CSV file displays in GitLab after making changes.

These parsing requirements only affect the visual rendering of CSV files and do not impact the actual
file content stored in your repository.

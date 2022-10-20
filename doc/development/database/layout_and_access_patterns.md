---
stage: Data Stores
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Best practices for data layout and access patterns

Certain patterns of data access, and especially data updates, can exacerbate strain
on the database. Avoid them if possible.

This document lists some patterns to avoid, with recommendations for alternatives.

## High-frequency updates, especially to the same row

Avoid single database rows that are updated by many transactions at the same time.

- If many processes attempt to update the same row simultaneously, they queue up
  as each transaction locks the row for writing. As this can significantly increase
  transaction timings, the Rails connection pools can saturate, leading to
  application-wide downtime.
- For each row update, PostgreSQL inserts a new row version and deletes the old one.
  In high-traffic scenarios, this approach can cause vacuum and WAL (write-ahead log)
  pressure, reducing database performance.

This pattern often happens when an aggregate is too expensive to compute for each
request, so a running tally is kept in the database. If you need such an aggregate,
consider keeping a running total in a single row, plus a small working set of
recently added data, such as individual increments:

- When introducing new data, add it to the working set. These inserts do not
  cause lock contention.
- When calculating the aggregate, combine the running total with a live aggregate
  from the working set, providing an up-to-date result.
- Add a periodic job that incorporates the working set into the running total and
  clears it in a transaction, bounding the amount of work needed by a reader.

## Wide tables

PostgreSQL organizes rows into 8 KB pages, and operates on one page at a time.
By minimizing the width of rows in a table, we improve the following:

- Sequential and bitmap index scan performance, because fewer pages must be
  scanned if each contains more rows.
- Vacuum performance, because vacuum can process more rows in each page.
- Update performance, because during a (non-HOT) update, each index must be
  updated for every row update.

Mitigating wide tables is one part of the database team's
[100 GB table initiative](../../architecture/blueprints/database_scaling/size-limits.md),
as wider tables can fit fewer rows in 100 GB.

When adding columns to a table, consider if you intend to access the data in the
new columns by itself, in a one-to-one relationship with the other columns of the
table. If so, the new columns could be a good candidate for splitting to a new table.

Several tables have already been split in this way. For example:

- `search_data` is split from `issues`.
- `project_pages_metadata` is split from `projects`.
- `merge_request_diff_details` is split from `merge_request_diffs`

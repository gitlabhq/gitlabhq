---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Best practices for data layout and access patterns
---

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

## Data model trade-offs

Certain tables, like `users`, `namespaces`, and `projects`, can get very wide.
These tables are usually central to the application, and used very often.

Why is this a problem?

- Many of these columns are included in indexes, which leads to index write amplification.
  When the number of indexes on the table is more than 16, it affects query planning,
  and may lead to [light-weight lock (LWLock) contention](https://gitlab.com/groups/gitlab-org/-/epics/11543).
- Updates in PostgreSQL are implemented as a combination of delete and insert. This means that each column,
  even if rarely used, is copied over and over again, on each update. This affects the amount of generated
  write ahead log (WAL).
- When there is a column that is frequently updated, each update results in all table columns
  being copied. Again, this results in increase of generated WAL, and creates more work for
  auto-vacuum.
- PostgreSQL stores data as rows, or tuples in a page. Wide rows reduce the number of tuples per page,
  and this affects read performance.

A possible solution to this problem is to keep only the most important columns on the main table,
and extract the rest into different tables, having one-to-one relationship with the main table.
Good candidates are columns that are either very frequently updated, for example `last_activity_at`,
or columns that are rarely updated and/or used, like activation tokens.

The trade-off that comes with such extraction is that index-only scans are no longer possible.
Instead, the application must either join to the new table or execute an additional query. The performance impacts
of this should be weighed against the benefits of the vertical table split.

There is a very good episode on this topic on the [PostgresFM](https://postgres.fm) podcast,
where @NikolayS of [PostgresAI](https://postgres.ai/) and @michristofides of [PgMustard](https://www.pgmustard.com/)
discuss this topic in more depth - [https://postgres.fm/episodes/data-model-trade-offs](https://postgres.fm/episodes/data-model-trade-offs).

### Example

Lets look at the `users` table, which at of the time of writing has 75 columns.
We can see a few groups of columns that match the above criteria, and are good candidates
for extraction:

- OTP related columns, like `encrypted_otp_secret`, `otp_secret_expires_at`, etc.
  There are few of these columns, and once populated they should not be updated often (if at all).
- Columns related to email confirmation - `confirmation_token`, `confirmation_sent_at`,
  and `confirmed_at`. Once populated these are most likely never updated.
- Timestamps like `password_expires_at`, `last_credential_check_at`, and `admin_email_unsubscribed_at`.
  Such columns are either updated very often, or not at all. It will be better if they are in a separate table.
- Various tokens (and columns related to them), like `unlock_token`, `incoming_email_token`, and `feed_token`.

Let's focus on `users.incoming_email_token` - every user on GitLab.com has one set, and this token is rarely updated.

In order to extract it from `users` into a new table, we'll have to do the following:

1. Release M [example](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141561)
   - Create table (release M)
   - Update the application to read from the new table, and fallback to the original column when there is no data yet.
   - Start to back-fill the new table
1. Release N [example](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141833)
   - Finalize the background migration doing the back-fill. This should be done in the next release *after* a [required stop](../../update/upgrade_paths.md).
1. Release N + 1 [example](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141835)
   - Update the application to read and write from the new table only.
   - Ignore the original column. This starts the process of safely removing database columns, as described in our [guides](avoiding_downtime_in_migrations.md#dropping-columns).
1. Release N + 2 [example](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142086)
   - Drop the original column.
1. Release N + 3 [example](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142087)
   - Remove the ignore rule for the original column.

While this is a lengthy process, it's needed in order to do the extraction
without disrupting the application. Once completed, the original column and the related index will
no longer exists on the `users` table, which will result in improved performance.

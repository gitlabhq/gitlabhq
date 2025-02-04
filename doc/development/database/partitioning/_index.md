---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Database table partitioning
---

WARNING:
If you have questions not answered below, check for and add them
to [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/398650).
Tag `@gitlab-org/database-team/triage` and we'll get back to you with an
answer as soon as possible. If you get an answer in Slack, document
it on the issue as well so we can update this document in the future.

Table partitioning is a powerful database feature that allows a table's
data to be split into smaller physical tables that act as a single large
table. If the application is designed to work with partitioning in mind,
there can be multiple benefits, such as:

- Query performance can be improved greatly, because the database can
  cheaply eliminate much of the data from the search space, while still
  providing full SQL capabilities.

- Bulk deletes can be achieved with minimal impact on the database by
  dropping entire partitions. This is a natural fit for features that need
  to periodically delete data that falls outside the retention window.

- Administrative tasks like `VACUUM` and index rebuilds can operate on
  individual partitions, rather than across a single massive table.

Unfortunately, not all models fit a partitioning scheme, and there are
significant drawbacks if implemented incorrectly. Additionally,
**tables can only be partitioned at their creation**, making it nontrivial
to apply partitioning to a busy database. A suite of migration tools are available
to enable backend developers to partition existing tables, but the
migration process is rather heavy, taking multiple steps split across
several releases. Due to the limitations of partitioning and the related
migrations, you should understand how partitioning fits your use case
before attempting to leverage this feature.

The partitioning migration helpers work by creating a partitioned duplicate
of the original table and using a combination of a trigger and a background
migration to copy data into the new table. Changes to the original table
schema can be made in parallel with the partitioning migration, but they
must take care to not break the underlying mechanism that makes the migration
work. For example, if a column is added to the table that is being
partitioned, both the partitioned table and the trigger definition must
be updated to match.

## Determine when to use partitioning

While partitioning can be very useful when properly applied, it's
imperative to identify if the data and workload of a table naturally fit a
partitioning scheme. Understand a few details to decide if partitioning
is a good fit for your particular problem:

- **Table partitioning**. A table is partitioned on a partition key, which is a
  column or set of columns which determine how the data is split across the
  partitions. The partition key is used by the database when reading or
  writing data, to decide which partitions must be accessed. The
  partition key should be a column that would be included in a `WHERE`
  clause on almost all queries accessing that table.

- **How the data is split**. What strategy does the database use
  to split the data across the partitions?

## Determine the appropriate partitioning strategy

The available partitioning strategy choices are `date range`, `int range`, `hash`, and `list`.

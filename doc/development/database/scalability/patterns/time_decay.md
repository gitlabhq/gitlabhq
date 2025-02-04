---
stage: Data Access
group: Database Frameworks
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 'Learn how to operate on large time-decay data'
title: Time-decay data
---

This document describes the *time-decay pattern* introduced in the
[Database Scalability Working Group](https://handbook.gitlab.com/handbook/company/working-groups/database-scalability/#time-decay-data).
We discuss the characteristics of time-decay data, and propose best practices for GitLab development
to consider in this context.

Some datasets are subject to strong time-decay effects, in which recent data is accessed far more
frequently than older data. Another aspect of time-decay: with time, some types of data become
less important. This means we can also move old data to a bit less durable (less available) storage,
or even delete the data, in extreme cases.

Those effects are usually tied to product or application semantics. They can vary in the degree
that older data are accessed, and how useful or required older data are to the users or the
application.

Let's first consider entities with no inherent time-related bias for their data.

A record for a user or a project may be equally important and frequently accessed, irrelevant to when
it was created. We cannot predict by using a user's `id` or `created_at` how often the related
record is accessed or updated.

On the other hand, a good example for datasets with extreme time-decay effects are logs and time
series data, such as events recording user actions.

Most of the time, that type of data may have no business use after a couple of days or weeks, and
quickly become less important even from a data analysis perspective. They represent a snapshot that
quickly becomes less and less relevant to the current state of the application, until at
some point it has no real value.

In the middle of the two extremes, we can find datasets that have useful information that we want to
keep around, but with old records seldom being accessed after an initial (small) time period after
creation.

## Characteristics of time-decay data

We are interested in datasets that show the following characteristics:

- **Size of the dataset:** they are considerably large.
- **Access methods:** we can filter the vast majority of queries accessing the dataset
  by a time related dimension or a categorical dimension with time decay effects.
- **Immutability:** the time-decay status does not change.
- **Retention:** whether we want to keep the old data or not, or whether old
  data should remain accessible by users through the application.

### Size of the dataset

There can be datasets of variable sizes that show strong time-decay effects, but in the context of
this blueprint, we intend to focus on entities with a **considerably large dataset**.

Smaller datasets do not contribute significantly to the database related resource usage, nor do they
inflict a considerable performance penalty to queries.

In contrast, large datasets over about 50 million records, or 100 GB in size, add a significant
overhead to constantly accessing a really small subset of the data. In those cases, we would want to
use the time-decay effect in our advantage and reduce the actively accessed dataset.

### Data access methods

The second and most important characteristic of time-decay data is that most of the time, we are
able to implicitly or explicitly access the data using a date filter,
**restricting our results based on a time-related dimension**.

There can be many such dimensions, but we focus only on the creation date as it is both
the most commonly used, and the one that we can control and optimize against. It:

- Is immutable.
- Is set when the record is created
- Can be tied to physically clustering the records, without having to move them around.

It's important to add that even if time-decay data are not accessed that way by the application by
default, you can make the vast majority of the queries explicitly filter the data in such
a way. **Time decay data without such a time-decay related access method are of no use from an optimization perspective, as there is no way to set and follow a scaling pattern.**

We are not restricting the definition to data that are always accessed using a time-decay related
access method, as there may be some outlier operations. These may be necessary and we can accept
them not scaling, if the rest of the access methods can scale. An example:
an administrator accessing all past events of a specific type, while all other operations only access
a maximum of a month of events, restricted to 6 months in the past.

### Immutability

The third characteristic of time-decay data is that their **time-decay status does not change**.
Once they are considered "old", they cannot switch back to "new" or relevant again.

This definition may sound trivial, but we have to be able to make operations over "old" data **more**
expensive (for example, by archiving or moving them to less expensive storage) without having to worry about
the repercussions of switching back to being relevant and having important application operations
underperforming.

Consider as a counter example to a time-decay data access pattern an application view that presents
issues by when they were updated. We are also interested in the most recent data from an "update"
perspective, but that definition is volatile and not actionable.

### Retention

Finally, a characteristic that further differentiates time-decay data in sub-categories with
slightly different approaches available is **whether we want to keep the old data or not**
(for example, retention policy) and/or
**whether old data is accessible by users through the application**.

#### (optional) Extended definition of time-decay data

As a side note, if we extend the aforementioned definitions to access patterns that restrict access
to a well defined subset of the data based on a clustering attribute, we could use the time-decay
scaling patterns for many other types of data.

As an example, consider data that are only accessed while they are labeled as active, like To-Dos
not marked as done, pipelines for unmerged merge requests (or a similar not time based constraint), etc.
In this case, instead of using a time dimension to define the decay, we use a categorical dimension
(that is, one that uses a finite set of values) to define the subset of interest. As long as that
subset is small compared to the overall size of the dataset, we could use the same approach.

Similarly, we may define data as old based both on a time dimension and additional status attributes,
such as CI pipelines that failed more than 6 months ago.

## Time-decay data strategies

### Partition tables

This is the acceptable best practice for addressing time-decay data from a pure database perspective.
You can find more information on table partitioning for PostgreSQL in the
[documentation page for table partitioning](https://www.postgresql.org/docs/12/ddl-partitioning.html).

Partitioning by date intervals (for example, month, year) allows us to create much smaller tables
(partitions) for each date interval and only access the most recent partitions for any
application-related operation.

We have to set the partitioning key based on the date interval of interest, which may depend on two
factors:

1. **How far back in time do we need to access data for?**
   Partitioning by week is of no use if we always access data for a year back, as we would have to
   execute queries over 52 different partitions (tables) each time. As an example for that consider the
   activity feed on the profile of any GitLab user.

   In contrast, if we want to just access the last 7 days of created records, partitioning by year
   would include too many unnecessary records in each partition, as is the case for `web_hook_logs`.
1. **How large are the partitions created?**
   The major purpose of partitioning is accessing tables that are as small as possible. If they get too
   large by themselves, queries start underperforming. We may have to re-partition (split) them
   in even smaller partitions.

The perfect partitioning scheme keeps **all queries over a dataset almost always over a single partition**,
with some cases going over two partitions and seldom over multiple partitions being
an acceptable balance. We should also target for **partitions that are as small as possible**, below
5-10M records and/or 10 GB each maximum.

Partitioning can be combined with other strategies to either prune (drop) old partitions, move them
to cheaper storage inside the database or move them outside of the database (archive or use of other
types of storage engines).

As long as we do not want to keep old records and partitioning is used, pruning old data has a
constant, for all intents and purposes zero, cost compared to deleting the data from a huge table
(as described in the following sub-section). We just need a background worker to drop old partitions
whenever all the data inside that partition get out of the retention policy's period.

As an example, if we only want to keep records no more than 6 months old and we partition by month,
we can safely keep the 7 latest partitions at all times (current month and 6 months in the past).
That means that we can have a worker dropping the 8th oldest partition at the start of each month.

Moving partitions to cheaper storage inside the same database is relatively simple in PostgreSQL
through the use of [tablespaces](https://www.postgresql.org/docs/12/manage-ag-tablespaces.html).
It is possible to specify a tablespace and storage parameters for each partition separately, so the
approach in this case would be to:

1. Create a new tablespace on a cheaper, slow disk.
1. Set the storage parameters higher on that new tablespace so that the PostgreSQL optimizer knows that the disks are slower.
1. Move the old partitions to the slow tablespace automatically by using background workers.

Finally, moving partitions outside of the database can be achieved through database archiving or
manually exporting the partitions to a different storage engine (more details in the dedicated
sub-section).

### Prune old data

If we don't want to keep old data around in any form, we can implement a pruning strategy and
delete old data.

It's a simple-to-implement strategy that uses a pruning worker to delete past data. As an example
that we further analyze below, we are pruning old `web_hook_logs` older than 90 days.

The disadvantage of such a solution over large, non-partitioned tables is that we have to manually
access and delete all the records that are considered as not relevant any more. That is a very
expensive operation, due to multi-version concurrency control in PostgreSQL. It also leads to the
pruning worker not being able to catch up with new records being created, if that rate exceeds a
threshold, as is the case of [`web_hook_logs`](https://gitlab.com/gitlab-org/gitlab/-/issues/256088)
at the time of writing this document.

For the aforementioned reasons, our proposal is that
**we should base any implementation of a data retention strategy on partitioning**,
unless there are strong reasons not to.

### Move old data outside of the database

In most cases, we consider old data as valuable, so we do not want to prune them. If at the same
time, they are not required for any database related operations (for example, directly accessed or used in
joins and other types of queries), we can move them outside of the database.

That does not mean that they are not directly accessible by users through the application; we could
move data outside the database and use other storage engines or access types for them, similarly to
offloading metadata but only for the case of old data.

In the simplest use case we can provide fast and direct access to recent data, while allowing users
to download an archive with older data. This is an option evaluated in the `audit_events` use case.
Depending on the country and industry, audit events may have a very long retention period, while
only the past months of data are actively accessed through GitLab interface.

Additional use cases may include exporting data to a data warehouse or other types of data stores as
they may be better suited for processing that type of data. An example can be JSON logs that we
sometimes store in tables: loading such data into a BigQuery or a columnar store like Redshift may
be better for analyzing/querying the data.

We might consider a number of strategies for moving data outside of the database:

1. Streaming this type of data into logs and then move them to secondary storage options
   or load them to other types of data stores directly (as CSV/JSON data).
1. Creating an ETL process that exports the data to CSV, uploads them to object storage,
   drops this data from the database, and then loads the CSV into a different data store.
1. Loading the data in the background by using the API provided by the data store.

This may be a not viable solution for large datasets; as long as bulk uploading using files is an
option, it should outperform API calls.

## Use cases

### Web hook logs

Related epic: [Partitioning: `web_hook_logs` table](https://gitlab.com/groups/gitlab-org/-/epics/5558)

The important characteristics of `web_hook_logs` are the following:

1. Size of the dataset: it is a really large table. At the moment we decided to
   partition it (`2021-03-01`), it had roughly 527M records and a total size of roughly 1 TB

   - Table: `web_hook_logs`
   - Rows: approximately 527M
   - Total size: 1.02 TiB (10.46%)
   - Table size: 713.02 GiB (13.37%)
   - Index(es) size: 42.26 GiB (1.10%)
   - TOAST size: 279.01 GiB (38.56%)

1. Access methods: we always request for the past 7 days of logs at max.
1. Immutability: it can be partitioned by `created_at`, an attribute that does not change.
1. Retention: there is a 90 days retention policy set for it.

Additionally, we were at the time trying to prune the data by using a background worker
(`PruneWebHookLogsWorker`), which could not [keep up with the rate of inserts](https://gitlab.com/gitlab-org/gitlab/-/issues/256088).

As a result, on March 2021 there were still not deleted records since July 2020 and the table was
increasing in size by more than 2 million records per day instead of staying at a more or less
stable size.

Finally, the rate of inserts has grown to more than 170 GB of data per month by March 2021 and keeps
on growing, so the only viable solution to pruning old data was through partitioning.

Our approach was to partition the table per month as it aligned with the 90 days retention policy.

The process required follows:

1. Decide on a partitioning key

   Using the `created_at` column is straightforward in this case: it is a natural
   partitioning key when a retention policy exists and there were no conflicting access patterns.

1. After we decide on the partitioning key, we can create the partitions and backfill
   them (copy data from the existing table). We can't just partition an existing table;
   we have to create a new partitioned table.

   So, we have to create the partitioned table and all the related partitions, start copying everything
   over, and also add sync triggers so that any new data or updates/deletes to existing data can be
   mirrored to the new partitioned table.

   [MR with all the necessary details on how to start partitioning a table](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/55938)

   It required 15 days and 7.6 hours to complete that process.

1. One milestone after the initial partitioning starts, clean up after the background migration
   used to backfill and finish executing any remaining jobs, retry failed jobs, etc.

   [MR with all the necessary details](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/57580)

1. Add any remaining foreign keys and secondary indexes to the partitioned table. This brings
   its schema on par with the original non partitioned table before we can swap them in the next milestone.

   We are not adding them at the beginning as they are adding overhead to each insert and they
   would slow down the initial backfilling of the table (in this case for more than half a billion
   records, which can add up significantly). So we create a lightweight, *vanilla* version of the
   table, copy all the data and then add any remaining indexes and foreign keys.

1. Swap the base table with partitioned copy: this is when the partitioned table
   starts actively being used by the application.

   Dropping the original table is a destructive operation, and we want to make sure that we had no
   issues during the process, so we keep the old non-partitioned table. We also switch the sync trigger
   the other way around so that the non-partitioned table is still up to date with any operations
   happening on the partitioned table. That allows us to swap back the tables if it is necessary.

   [MR with all the necessary details](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/60184)

1. Last step, one milestone after the swap: drop the non-partitioned table

   [Issue with all the necessary details](https://gitlab.com/gitlab-org/gitlab/-/issues/323678)

1. After the non-partitioned table is dropped, we can add a worker to implement the
   pruning strategy by dropping past partitions.

   In this case, the worker makes sure that only 4 partitions are always active (as the
   retention policy is 90 days) and drop any partitions older than four months. We have to keep 4
   months of partitions while the current month is still active, as going 90 days back takes you to
   the fourth oldest partition.

### Audit events

Related epic: [Partitioning: Design and implement partitioning strategy for audit events](https://gitlab.com/groups/gitlab-org/-/epics/3206)

The `audit_events` table shares a lot of characteristics with the `web_hook_logs` table discussed
in the previous sub-section, so we focus on the points they differ.

The consensus was that
[partitioning could solve most of the performance issues](https://gitlab.com/groups/gitlab-org/-/epics/3206#note_338157248).

In contrast to most other large tables, it has no major conflicting access patterns: we could switch
the access patterns to align with partitioning by month. This is not the case for example for other
tables, which even though could justify a partitioning approach (for example, by namespace), they have many
conflicting access patterns.

In addition, `audit_events` is a write-heavy table with very few reads (queries) over it and has a
very simple schema, not connected with the rest of the database (no incoming or outgoing FK
constraints) and with only two indexes defined over it.

The later was important at the time as not having Foreign Key constraints meant that we could
partition it while we were still in PostgreSQL 11. *This is not a concern any more now that we have
moved to PostgreSQL 12 as a required default, as can be seen for the `web_hook_logs` use case above.*

The migrations and steps required for partitioning the `audit_events` are similar to
the ones described in the previous sub-section for `web_hook_logs`. There is no retention
strategy defined for `audit_events` at the moment, so there is no pruning strategy
implemented over it, but we may implement an archiving solution in the future.

What's interesting on the case of `audit_events` is the discussion on the necessary steps that we
had to follow to implement the UI/UX Changes needed to
[encourage optimal querying of the partitioned](https://gitlab.com/gitlab-org/gitlab/-/issues/223260).
It can be used as a starting point on the changes required on the application level
to align all access patterns with a specific time-decay related access method.

### CI tables

NOTE:
Requirements and analysis of the CI tables use case: still a work in progress. We intend
to add more details after the analysis moves forward.

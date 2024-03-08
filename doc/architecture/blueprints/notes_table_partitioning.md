---
status: ongoing
creation-date: "2023-12-22"
authors: [ "@engwan", "@euko" ]
owning-stage: "~devops::plan"
description: 'Notes partitioning design'
participating-stages: [ "~devops::create" ]
---

<!-- vale gitlab.FutureTense = NO -->

# Partitioning the notes table

## Problem

The `notes` table is one of the largest PostgreSQL DB tables in GitLab,
whose size in the `.com` production database exceeded 1.5TB as of Nov 2023,
[increasingly endangering](https://gitlab.com/groups/gitlab-org/-/epics/6211)
the reliability of GitLab.com and large self-managed instances.

Available partitioning or sharding methods must be evaluated for the table
and executed as early as possible to meet the 100GB per table target size limit.

## Overview of `notes` table

### The table composition as of Nov 2023

The majority of the records in the table were for merge requests.

| Noteable type  | % of total records | Num. records |
|----------------|--------------------|--------------|
| Merge Request  | 67%                | 1002272868   |
| Issue          | 23%                | 348020507    |
| Commit         | <~ 5 %             | 67790930     |
| Epic           | <~ 0.05 %          | 6196244      |
| Others         | <~ 5%              |              |
| Total          |                    | 1488612100   |

The `note` and `note_html` columns took up 183GB and 580GB respectively,
occupying ~77% of the storage space used by the table and its supporting indexes.

`note` stores the raw note texts and `note_html` caches the HTML renders of the raw note texts.

| Column               | Size (GB)    | % of Total |
|----------------------|--------------|------------|
| `note`               | 183 GB       | 16%        |
| `note_html`          | 580 GB       | 51%        |
| MR related columns   | 94 GB        | 0.8%       |
| Other columns        | 383 GB       | 24%        |
| Total                | 1,240 GB     | ~100%      |

The indexes on the table took up the remaining 300 GB or so.

### Design of the `notes` table

`notes` has polymorphic associations through the following three columns.

- `noteable_type`: stores the type of a noteable, for example `Issue`, `MergeRequest`, `Commit`.

- `noteable_id`: stores the ID of a noteable.

- `commit_id`: stores the Git SHA of a commit.

When a note's `noteable_type` is `Commit`, `noteable_id` is `NULL` and `commit_id` is used to reference the commit.

The associated models are: `MergeRequest`, `Vulnerability`, `Epic`, `Snippet`, `Commit`,
`DesignManagement::Design`, `Issue`, `AlertManagement::Alert` and `AbuseReport`

All notes should belong to a namespace through noteable except for abuse notes that are instance-level.

#### Reducing contention on the lock_manager lwlocks

The polymorphic associations for the table have an important implication for partitioning.

Paritition must be done in a way that the queries targeting the table accesses
the minimum number of partitions
or in a manner that does not deplete the 16 fastpath locks to
[reduce contention on the lock_manager lwlocks](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/2301).

For example, the most common access pattern for the `notes` table is fetching the notes for a noteable such as Issue.
If the table were to be partitioned by `id` (range, hash or list), the following query could end up hitting
all partitions: `SELECT * FROM notes WHERE noteable_type='Issue' AND noteable_id=1;`.
Suppose we needed to get notes by `id`s to display user activities or TODOs instead:
`SELECT * FROM todos INNER JOIN notes WHERE notes.id=todos.note_id AND todos.id IN (1, 2, 3);`.
PostgreSQL would be able to prune out the partitions that didn't contain the `note_id`s and only access
the minimum partitions needed to execute the query.

It's challenging that many columns in the `notes` table are nullable including the columns used
for polymorphic associations as well as namespaces and projects while
partitioning usually requires partitioning columns to be non-nullable.

## Partitioning methods

Here we consider various options for partitioning and restructuring the `notes` table.

### 1. Split the table by domain model

Splitting into separate tables by domain models (issues, MRs, epics)
aligns with best practices but the resulting tables would still exceed 100GB.
For example, we could have separate `issue_notes`, `merge_request_notes` and `epic_notes` tables.

**Benefits:**

- Aligns with domain models and [the composition of the table](#the-table-composition-as-of-nov-2023)
  - There are many merge request specific columns that interfere with applying other partitioning strategies,
and contribute to index bloat and non-ideal data alignments.

- Addresses [polymorphic associations](../../development/database/polymorphic_associations.md)
and constraints issues
  - On top of having polymorphic associations which are discouraged,
the presence of the `commit_id` column storing Git SHA hashes prevents utilizing database constraints fully.

**Drawbacks:**

- **Significant** code changes would be required across the codebase

- Even after splitting by domain,
the resulting domain tables would exceed the 100GB target size limit and each table would need to be partitioned.

### 2. Partition by hash using `namespace_id`

Given the typical access pattern of retriving notes for a noteable,
we might consider using `noteable_type`, `noteable_id`, and `commit_id` as hash key columns.
However, some queries like this one used to preload notes work with `id`s,
`namespace_id` could be [the better choice as the sole hash key](https://gitlab.com/gitlab-org/gitlab/-/issues/416127#note_1467349405)

**Benefits:**

- We can achieve the 100GB target size limit without additional work although
some partitions may grow at a faster rate in the future.

**Drawbacks:**

- The primary key of a hash partitioned table must include the hash key columns,
but all proposed hash keys here are nullable, and thus cannot be part of the primary key and lose
referential integrity. However, this drawback only exists when partitioning by
the polymorphic association columns. `namespace_id` would soon become the sharding key
for the `notes` table for the Cells 1.0.

- `namespace_id` could be sharding keys for all the tables referencing the `notes` table
allowing us to easily add foreign keys to the partitioned `notes` table as the work for
Cells 1.0 progresses.

- Some code change is still required to update all the notes queries to include `namespace_id`.

- This method does not address any of the existing structural problems
like polymorphic associations or too many merge request specific columns (and the consequences)

### 3. Vertical split of the table

A vertical split of the two largest columns `note` and `note_html` or just `note_html`
into a separate table can reduce overall storage needs.
It's worth noting that the notes table cannot significantly benefit
from PostgreSQL's [TOAST feature](https://www.postgresql.org/docs/current/storage-toast.html).
Most note texts (`note` column) do not exceed the 2kB default threshold
necessary to trigger compression and OUT-OF-LINE storage.

The table for the vertically split column(s)
could be [partitioned by int range](../../development/database/partitioning/int_range.md)
using the `notes` table's `id` column.

**Benefits:**

- Vertical partitioning of `note` and `note_html` columns can improve the table layout
and compact the tuple sizes of the remaining `notes` table to allow for better spatial locality.

- It might be viewed as a more incremental approach as the `notes` table would remain in place.

**Drawbacks:**

- In order to avoid [the lock contention problem](#design-of-the-notes-table),
a batching strategy must be implemented when preloading the table containing the vertically split columns.
Suppose there are 16+ partitions. The first partition contains the data for the `notes` records with IDs `<100`.
The second partition contains the data for the `notes` records with IDs `>=100` and so on.
To make sure a preload query does not access too many partitions,
we can break it into several queries:
`SELECT * FROM p_notes_data WHERE note_id < 100 AND note_id IN (1, 100, 20000, 30000)`,
`SELECT * FROM p_notes_data WHERE note_id >= 20000 AND note_id IN (1, 100, 20000, 30000)` and so on.

- `CacheMarkdownField`, the concern that `notes` uses, has implicit dependencies on other parts of the codebase.
The attempts to override them or transparently delegate the related methods do not work cleanly or easily.
Also [see the section on Markdown caching](#notes-on-db-based-markdown-caching)

- Additional partitioning work for the `notes` table is still required to meet the 100GB target size limit.

- This method does not address any of the existing structural problems
like polymorphic associations or too many merge request specific columns (and the consequences)

#### Notes on DB-based Markdown caching

Merge request notes follow the typical decay pattern
where the notes start losing relevance once their merge request become closed.
The same decay pattern may be applicable to other noteable types
and dropping the cached Markdown for the notes older than some period
could be a viable method to reduce the stored data.

One possible risk is that re-calculating older notes whose cached Markdown was dropped
could have a thrashing effect on both the Rails application and the PostgreSQL hosts.
In the past, it's been observed that rendering many notes and updating the cache severly strained
the application and the database whenever the cached Markdown version was bumped for notes.

It's worth investigating caching Markdown solely to Redis and
removing the database caching layer if the thrashing effect turns out to be less concerning.

### 4. Partition by list using `noteable_type`

We may consider partitioning the `notes` table itself by the values of the `noteable_type` column.

NOTE:
As of Mar 8th 2024, there is a `INVALID` non-null check constraint on `noteable_type`.
A small number of `notes` records without `noteable_type` have been found and removed from GitLab.com's production database.
The non-null check constraint is [planned to be validated in 17.0](https://gitlab.com/gitlab-org/gitlab/-/issues/443667)

**Benefits:**

- Almost all `notes` queries contain `noteable_type` and that makes the column an ideal choice to use
when partitionining by list.

- Partitioning by list with `noteable_type` can allow us to furthur partition
the resulting partitions by domain.

**Drawbacks:**

- Sub-partitioning still requires partitioning keys to be present in the root table's primary key.

- This approach requires adding many foreign keys to the tables referencing the `notes` table.
The partitioned table would use a composite primary key `(noteable_type, id)` so
`noteable_type` would need to be first added to all the referencing tables and backfilled.

- More code change might be required to ensure Active Record models work with the partitioned table
that uses the composite primary key.

- This method does not address any of the existing structural problems
like polymorphic associations or too many merge request specific columns. However,
the possibility of sub-partitioning by domain does dampen the drawback.

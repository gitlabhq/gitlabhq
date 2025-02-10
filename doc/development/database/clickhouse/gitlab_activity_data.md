---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Store GitLab activity data in ClickHouse
---

## Overview of the existing implementation

### What is GitLab activity data

GitLab records activity data during its operation as users interact with the application. Most of these interactions revolve around the projects, issues, and merge requests domain objects. Users can perform several different actions and some of these actions are recorded in a separate PostgreSQL database table called `events`.

Example events:

- Issue opened
- Issue reopened
- User joined a project
- Merge Request merged
- Repository pushed
- Snippet created

### Where is the activity data used

Several features use activity data:

- The user's [contribution calendar](../../../user/profile/contributions_calendar.md) on the profile page.
- Paginated list of the user's contributions.
- Paginated list of user activity for a Project and a Group.
- [Contribution analytics](../../../user/group/contribution_analytics/_index.md).

### How is the activity data created

The activity data is usually generated on the service layer when a specific operation is executed by the user. The persistence characteristics of an `events` record depend on the implementation of the service. Two main approaches exist:

1. In the database transaction where the actual event occurs.
1. After the database transaction (which could be delayed).

The above-mentioned mechanics provide a "mostly" consistent stream of `events`.

For example, consistently recording an `events` record:

```ruby
ApplicationRecord.transaction do
  issue.closed!
  Event.create!(action: :closed, target: issue)
end
```

Example, unsafe recording of an `events` record:

```ruby
ApplicationRecord.transaction do
  issue.closed!
end

# If a crash happens here, the event will not be recorded.
Event.create!(action: :closed, target: issue)
```

### Database table structure

The `events` table uses [polymorphic association](https://guides.rubyonrails.org/association_basics.html#polymorphic-associations) to allow associating different database tables (issues, merge requests, etc.) with a record. A simplified database structure:

```sql
   Column    |           Type            | Nullable |              Default               | Storage  |
-------------+--------------------------+-----------+----------+------------------------------------+
 project_id  | integer                   |          |                                    | plain    |
 author_id   | integer                   | not null |                                    | plain    |
 target_id   | integer                   |          |                                    | plain    |
 created_at  | timestamp with time zone  | not null |                                    | plain    |
 updated_at  | timestamp with time zone  | not null |                                    | plain    |
 action      | smallint                  | not null |                                    | plain    |
 target_type | character varying         |          |                                    | extended |
 group_id    | bigint                    |          |                                    | plain    |
 fingerprint | bytea                     |          |                                    | extended |
 id          | bigint                    | not null | nextval('events_id_seq'::regclass) | plain    |
```

Some unexpected characteristics due to the evolving database design:

- The `project_id` and the `group_id` columns are mutually exclusive, internally we call them resource parent.
  - Example 1: for an issue opened event, the `project_id` field is populated.
  - Example 2: for an epic-related event, the `group_id` field is populated (epic is always part of a group).
- The `target_id` and `target_type` column pair identifies the target record.
  - Example: `target_id=1` and `target_type=Issue`.
  - When the columns are `null`, we refer to an event which has no representation in the database. For example a repository `push` action.
- Fingerprint is used in some cases to later alter the event based on some metadata change. This approach is mostly used for Wiki pages.

### Database record modifications

Most of the data is written once however, we cannot say that the table is append-only. A few use cases where actual row updates and deletions happen:

- Fingerprint-based update for certain Wiki page records.
- When user or an associated resource is deleted, the event rows are also deleted.
  - The deletion of the associated `events` records happens in batches.

### Current performance problems

- The table uses significant disk space.
- Adding new events may significantly increase the database record count.
- Implementing data pruning logic is difficult.
- Time-range-based aggregations are not performant enough, some features may break due to slow database queries.

### Example queries

NOTE:
These queries have been significantly simplified from the actual queries from production.

Database query for the user's contribution graph:

```sql
SELECT DATE(events.created_at), COUNT(*)
FROM events
WHERE events.author_id = 1
AND events.created_at BETWEEN '2022-01-17 23:00:00' AND '2023-01-18 22:59:59.999999'
AND (
  (
    events.action = 5
  ) OR
  (
    events.action IN (1, 3) -- Enum values are documented in the Event model, see the ACTIONS constant in app/models/event.rb
    AND events.target_type IN ('Issue', 'WorkItem')
  ) OR
  (
    events.action IN (7, 1, 3)
    AND events.target_type = 'MergeRequest'
  ) OR
  (
    events.action = 6
  )
)
GROUP BY DATE(events.created_at)
```

Query for group contributions for each user:

```sql
SELECT events.author_id, events.target_type, events.action, COUNT(*)
FROM events
WHERE events.created_at BETWEEN '2022-01-17 23:00:00' AND '2023-03-18 22:59:59.999999'
AND events.project_id IN (1, 2, 3) -- list of project ids in the group
GROUP BY events.author_id, events.target_type, events.action
```

## Storing activity data in ClickHouse

### Data persistence

At the moment, there is no consensus about the way we would replicate data from the PostgreSQL database to ClickHouse. A few ideas that might work for the `events` table:

#### Record data immediately

This approach provides a simple way to keep the existing `events` table working while we're also sending data to the ClickHouse database. When an event record is created, ensure that it's created outside of the transaction. After persisting the data in PostgreSQL, persist it in ClickHouse.

```ruby
ApplicationRecord.transaction do
  issue.update!(state: :closed)
end

# could be a method to hide complexity
Event.create!(action: :closed, target: issue)
ClickHouse::Event.create(action: :closed, target: issue)
```

What's behind the implementation of `ClickHouse::Event` is not decided yet, it could be one of the following:

- ActiveRecord model directly connecting the ClickHouse database.
- REST API call to an intermediate service.
<!-- vale gitlab_base.Spelling = NO -->
- Enqueueing an event to an event-streaming tool (like Kafka).
<!-- vale gitlab_base.Spelling = YES -->

#### Replication of `events` rows

Assuming that the creation of `events` record is an integral part of the system, introducing another storage call might cause performance degradation in various code paths, or it could introduce significant complexity.

Rather than sending data to ClickHouse on event creation time, we would move this processing in the background by iterating over the `events` table and sending the newly created database rows.

By keeping track of which records have been sent over ClickHouse, we could incrementally send data.

```ruby
last_updated_at = SyncProcess.last_updated_at

# oversimplified loop, we would probably batch this...
Event.where(updated_at > last_updated_at).each do |row|
  last_row = ClickHouse::Event.create(row)
end

SyncProcess.last_updated_at = last_row.updated_at
```

### ClickHouse database table structure

When coming up with the initial database structure, we must look at the way the data is queried.

We have two main use cases:

- Query data for a certain user, within a time range.
  - `WHERE author_id = 1 AND created_at BETWEEN '2021-01-01' AND '2021-12-31'`
  - Additionally, there might be extra `project_id` condition due to the access control check.
- Query data for a project or group, within a time range.
  - `WHERE project_id IN (1, 2) AND created_at BETWEEN '2021-01-01' AND '2021-12-31'`

The `author_id` and `project_id` columns are considered high-selectivity columns. By this we mean that optimizing the filtering of the `author_id` and the `project_id` columns is desirable for having performant database queries.

The most recent activity data is queried more often. At some point, we might just drop or relocate older data. Most of the features look back only a year.

For these reasons, we could start with a database table storing low-level `events` data:

```plantuml
hide circle

entity "events" as events {
  id : UInt64 ("primary key")
--
  project_id : UInt64
  group_id : UInt64
  target_id : UInt64
  target_type : String
  action : UInt8
  fingerprint : UInt64
  created_at : DateTime
  updated_at : DateTime
}
```

The SQL statement for creating the table:

```sql
CREATE TABLE events
(
    `id` UInt64,
    `project_id` UInt64 DEFAULT 0 NOT NULL,
    `group_id` UInt64 DEFAULT 0 NOT NULL,
    `author_id` UInt64 DEFAULT 0 NOT NULL,
    `target_id` UInt64 DEFAULT 0 NOT NULL,
    `target_type` LowCardinality(String) DEFAULT '' NOT NULL,
    `action` UInt8 DEFAULT 0 NOT NULL,
    `fingerprint` UInt64 DEFAULT 0 NOT NULL,
    `created_at` DateTime64(6, 'UTC') DEFAULT now() NOT NULL,
    `updated_at` DateTime64(6, 'UTC') DEFAULT now() NOT NULL
)
ENGINE = ReplacingMergeTree(updated_at)
ORDER BY id;
```

A few changes compared to the PostgreSQL version:

- `target_type` uses [an optimization](https://clickhouse.com/docs/en/sql-reference/data-types/lowcardinality) for low-cardinality column values.
- `fingerprint` becomes an integer and leverages a performant integer-based hashing function such as xxHash64.
- All columns get a default value, the 0 default value for the integer columns means no value. See the related [best practices](https://clickhouse.com/docs/en/cloud/bestpractices/avoid-nullable-columns).
- `NOT NULL` to ensure that we always use the default values when data is missing (different behavior compared to PostgreSQL).
- The "primary" key automatically becomes the `id` column due to the `ORDER BY` clause.

Let's insert the same primary key value twice:

```sql
INSERT INTO events (id, project_id, target_id, author_id, target_type, action) VALUES (1, 2, 3, 4, 'Issue', null);
INSERT INTO events (id, project_id, target_id, author_id, target_type, action) VALUES (1, 20, 30, 5, 'Issue', null);
```

Let's inspect the results:

```sql
SELECT * FROM events
```

- We have two rows with the same `id` value (primary key).
- The `null` `action` becomes `0`.
- The non-specified fingerprint column becomes `0`.
- The `DateTime` columns have the insert timestamp.

ClickHouse will eventually "replace" the rows with the same primary key in the background. When running this operation, the higher `updated_at` value takes precedence. The same behavior can be simulated with the `final` keyword:

```sql
SELECT * FROM events FINAL
```

Adding `FINAL` to a query can have significant performance consequences, some of the issues are documented in the [ClickHouse documentation](https://clickhouse.com/docs/en/sql-reference/statements/select/from#final-modifier).

We should always expect duplicated values in the table, so we must take care of the deduplication in query time.

### ClickHouse database queries

ClickHouse uses SQL for querying the data, in some cases, a PostgreSQL query can be used in ClickHouse without major modifications assuming that the underlying database structure is very similar.

Query for group contributions for each user (PostgreSQL):

```sql
SELECT events.author_id, events.target_type, events.action, COUNT(*)
FROM events
WHERE events.created_at BETWEEN '2022-01-17 23:00:00' AND '2023-03-18 22:59:59.999999'
AND events.project_id IN (1, 2, 3) -- list of project ids in the group
GROUP BY events.author_id, events.target_type, events.action
```

The same query would work in PostgreSQL however, we might see duplicated values in ClickHouse due to the way the table engine works. The deduplication can be achieved by using a nested `FROM` statement.

```sql
SELECT author_id, target_type, action, count(*)
FROM (
  SELECT
  id,
  argMax(events.project_id, events.updated_at) AS project_id,
  argMax(events.group_id, events.updated_at) AS group_id,
  argMax(events.author_id, events.updated_at) AS author_id,
  argMax(events.target_type, events.updated_at) AS target_type,
  argMax(events.target_id, events.updated_at) AS target_id,
  argMax(events.action, events.updated_at) AS action,
  argMax(events.fingerprint, events.updated_at) AS fingerprint,
  FIRST_VALUE(events.created_at) AS created_at,
  MAX(events.updated_at) AS updated_at
  FROM events
  WHERE events.created_at BETWEEN '2022-01-17 23:00:00' AND '2023-03-18 22:59:59.999999'
  AND events.project_id IN (1, 2, 3) -- list of project ids in the group
  GROUP BY id
) AS events
GROUP BY author_id, target_type, action
```

- Take the most recent column values based on the `updated_at` column.
- Take the first value for `created_at`, assuming that the first `INSERT` contains the correct value. An issue only when we don't sync `created_at` at all and the default value (`NOW()`) is used.
- Take the most recent `updated_at` value.

The query looks more complicated now because of the deduplication logic. The complexity can be hidden behind a database view.

### Optimizing the performance

The aggregation query in the previous section might not be performant enough for production use due to the large volume of data.

Let's add 1 million extra rows to the `events` table:

```sql
INSERT INTO events (id, project_id, author_id, target_id, target_type, action)  SELECT id, project_id, author_id, target_id, 'Issue' AS target_type, action FROM generateRandom('id UInt64, project_id UInt64, author_id UInt64, target_id UInt64, action UInt64') LIMIT 1000000;
```

Running the previous aggregation query in the console prints out some performance data:

```plaintext
1 row in set. Elapsed: 0.122 sec. Processed 1.00 million rows, 42.00 MB (8.21 million rows/s., 344.96 MB/s.)
```

The query returned 1 row (correctly) however, it had to process 1 million rows (full table). We can optimize the query with an index on the `project_id` column:

```sql
ALTER TABLE events ADD INDEX project_id_index project_id TYPE minmax GRANULARITY 10;
ALTER TABLE events MATERIALIZE INDEX project_id_index;
```

Executing the query returns much better figures:

```plaintext
Read 2 rows, 107.00 B in 0.005616811 sec., 356 rows/sec., 18.60 KiB/sec.
```

To optimize the date range filter on the `created_at` column, we could try adding another index on the `created_at` column.

#### Query for the contribution graph

Just to recap, this is the PostgreSQL query:

```sql
SELECT DATE(events.created_at), COUNT(*)
FROM events
WHERE events.author_id = 1
AND events.created_at BETWEEN '2022-01-17 23:00:00' AND '2023-01-18 22:59:59.999999'
AND (
  (
    events.action = 5
  ) OR
  (
    events.action IN (1, 3) -- Enum values are documented in the Event model, see the ACTIONS constant in app/models/event.rb
    AND events.target_type IN ('Issue', 'WorkItem')
  ) OR
  (
    events.action IN (7, 1, 3)
    AND events.target_type = 'MergeRequest'
  ) OR
  (
    events.action = 6
  )
)
GROUP BY DATE(events.created_at)
```

The filtering and the count aggregation is mainly done on the `author_id` and the `created_at` columns. Grouping the data by these two columns would probably give an adequate performance.

We could attempt adding an index on the `author_id` column however, we still need an additional index on the `created_at` column to properly cover this query. Besides, under the contribution graph, GitLab shows the list of ordered contributions of the user which would be great to get it efficiently via a different query with the `ORDER BY` clause.

For these reasons, it's probably better to use a ClickHouse projection which stores the events rows redundantly but we can specify a different sort order.

The ClickHouse query would be the following (with a slightly adjusted date range):

```sql
SELECT DATE(events.created_at) AS date, COUNT(*) AS count
FROM (
  SELECT
  id,
  argMax(events.created_at, events.updated_at) AS created_at
  FROM events
  WHERE events.author_id = 4
  AND events.created_at BETWEEN '2023-01-01 23:00:00' AND '2024-01-01 22:59:59.999999'
  AND (
    (
      events.action = 5
    ) OR
    (
      events.action IN (1, 3) -- Enum values are documented in the Event model, see the ACTIONS constant in app/models/event.rb
      AND events.target_type IN ('Issue', 'WorkItem')
    ) OR
    (
      events.action IN (7, 1, 3)
      AND events.target_type = 'MergeRequest'
    ) OR
    (
      events.action = 6
    )
  )
  GROUP BY id
) AS events
GROUP BY DATE(events.created_at)
```

The query does a full table scan, let's optimize it:

```sql
ALTER TABLE events ADD PROJECTION events_by_authors (
  SELECT * ORDER BY author_id, created_at -- different sort order for the table
);

ALTER TABLE events MATERIALIZE PROJECTION events_by_authors;
```

#### Pagination of contributions

Listing the contributions of a user can be queried in the following way:

```sql
SELECT events.*
FROM (
  SELECT
  id,
  argMax(events.project_id, events.updated_at) AS project_id,
  argMax(events.group_id, events.updated_at) AS group_id,
  argMax(events.author_id, events.updated_at) AS author_id,
  argMax(events.target_type, events.updated_at) AS target_type,
  argMax(events.target_id, events.updated_at) AS target_id,
  argMax(events.action, events.updated_at) AS action,
  argMax(events.fingerprint, events.updated_at) AS fingerprint,
  FIRST_VALUE(events.created_at) AS created_at,
  MAX(events.updated_at) AS updated_at
  FROM events
  WHERE events.author_id = 4
  GROUP BY id
  ORDER BY created_at DESC, id DESC
) AS events
LIMIT 20
```

ClickHouse supports the standard `LIMIT N OFFSET M` clauses, so we can request the next page:

```sql
SELECT events.*
FROM (
  SELECT
  id,
  argMax(events.project_id, events.updated_at) AS project_id,
  argMax(events.group_id, events.updated_at) AS group_id,
  argMax(events.author_id, events.updated_at) AS author_id,
  argMax(events.target_type, events.updated_at) AS target_type,
  argMax(events.target_id, events.updated_at) AS target_id,
  argMax(events.action, events.updated_at) AS action,
  argMax(events.fingerprint, events.updated_at) AS fingerprint,
  FIRST_VALUE(events.created_at) AS created_at,
  MAX(events.updated_at) AS updated_at
  FROM events
  WHERE events.author_id = 4
  GROUP BY id
  ORDER BY created_at DESC, id DESC
) AS events
LIMIT 20 OFFSET 20
```

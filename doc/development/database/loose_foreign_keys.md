---
stage: Tenant Scale
group: Cells Infrastructure
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Loose foreign keys
---

## Problem statement

In relational databases (including PostgreSQL), foreign keys provide a way to link
two database tables together, and ensure data-consistency between them. In GitLab,
[foreign keys](foreign_keys.md) are vital part of the database design process.
Most of our database tables have foreign keys.

With the ongoing database [decomposition work](https://gitlab.com/groups/gitlab-org/-/epics/6168),
linked records might be present on two different database servers. Ensuring data consistency
between two databases is not possible with standard PostgreSQL foreign keys. PostgreSQL
does not support foreign keys operating across multiple database servers.

Example:

- Database "Main": `projects` table
- Database "CI": `ci_pipelines` table

A project can have many pipelines. When a project is deleted, the associated `ci_pipeline` (via the
`project_id` column) records must be also deleted.

With a multi-database setup, this cannot be achieved with foreign keys.

## Asynchronous approach

Our preferred approach to this problem is eventual consistency. With the loose foreign keys
feature, we can configure delayed association cleanup without negatively affecting the
application performance.

### How it works

In the previous example, a record in the `projects` table can have multiple `ci_pipeline`
records. To keep the cleanup process separate from the actual parent record deletion,
we can:

1. Create a `DELETE` trigger on the `projects` table.
   Record the deletions in a separate table (`deleted_records`).
1. A job checks the `deleted_records` table every minute or two.
1. For each record in the table, delete the associated `ci_pipelines` records
   using the `project_id` column.

NOTE:
For this procedure to work, we must register which tables to clean up asynchronously.

## The `scripts/decomposition/generate-loose-foreign-key`

We built an automation tool to aid migration of foreign keys into loose foreign keys as part of
decomposition effort. It presents existing keys and allows chosen foreign keys to be automatically
converted into loose foreign keys. This ensures consistency between foreign key and loose foreign
key definitions, and ensures that they are properly tested.

WARNING:
We strongly advise you to use the automation script for swapping any foreign key to a loose foreign key.

The tool ensures that all aspects of swapping a foreign key are covered. This includes:

- Creating a migration to remove a foreign key.
- Updating `db/structure.sql` with the new migration.
- Updating `config/gitlab_loose_foreign_keys.yml` to add the new loose foreign key.
- Creating or updating a model's specs to ensure that the loose foreign key is properly supported.

The tool is located at `scripts/decomposition/generate-loose-foreign-key`:

```shell
$ scripts/decomposition/generate-loose-foreign-key -h

Usage: scripts/decomposition/generate-loose-foreign-key [options] <filters...>
    -c, --cross-schema               Show only cross-schema foreign keys
    -n, --dry-run                    Do not execute any commands (dry run)
    -r, --[no-]rspec                 Create or not a rspecs automatically
    -h, --help                       Prints this help
```

For the migration of cross-schema foreign keys, we use the `-c` modifier to show the foreign keys
yet to migrate:

```shell
$ scripts/decomposition/generate-loose-foreign-key -c
Re-creating current test database
Dropped database 'gitlabhq_test_ee'
Dropped database 'gitlabhq_geo_test_ee'
Created database 'gitlabhq_test_ee'
Created database 'gitlabhq_geo_test_ee'

Showing cross-schema foreign keys (20):
   ID | HAS_LFK |                                     FROM |                   TO |                         COLUMN |       ON_DELETE
    0 |       N |                                ci_builds |             projects |                     project_id |         cascade
    1 |       N |                         ci_job_artifacts |             projects |                     project_id |         cascade
    2 |       N |                             ci_pipelines |             projects |                     project_id |         cascade
    3 |       Y |                             ci_pipelines |       merge_requests |               merge_request_id |         cascade
    4 |       N |                   external_pull_requests |             projects |                     project_id |         cascade
    5 |       N |                     ci_sources_pipelines |             projects |                     project_id |         cascade
    6 |       N |                                ci_stages |             projects |                     project_id |         cascade
    7 |       N |                    ci_pipeline_schedules |             projects |                     project_id |         cascade
    8 |       N |                       ci_runner_projects |             projects |                     project_id |         cascade
    9 |       Y |             dast_site_profiles_pipelines |         ci_pipelines |                 ci_pipeline_id |         cascade
   10 |       Y |                   vulnerability_feedback |         ci_pipelines |                    pipeline_id |         nullify
   11 |       N |                             ci_variables |             projects |                     project_id |         cascade
   12 |       N |                                  ci_refs |             projects |                     project_id |         cascade
   13 |       N |                       ci_builds_metadata |             projects |                     project_id |         cascade
   14 |       N |                ci_subscriptions_projects |             projects |          downstream_project_id |         cascade
   15 |       N |                ci_subscriptions_projects |             projects |            upstream_project_id |         cascade
   16 |       N |                      ci_sources_projects |             projects |              source_project_id |         cascade
   17 |       N |         ci_job_token_project_scope_links |             projects |              source_project_id |         cascade
   18 |       N |         ci_job_token_project_scope_links |             projects |              target_project_id |         cascade
   19 |       N |                ci_project_monthly_usages |             projects |                     project_id |         cascade

To match foreign key (FK), write one or many filters to match against FROM/TO/COLUMN:
- scripts/decomposition/generate-loose-foreign-key (filters...)
- scripts/decomposition/generate-loose-foreign-key ci_job_artifacts project_id
- scripts/decomposition/generate-loose-foreign-key dast_site_profiles_pipelines
```

The command accepts a list of regular expressions to match from, to, or column
for the purpose of the foreign key generation. For example, run this to swap
all foreign keys for `ci_job_token_project_scope_links` for the decomposed database:

```shell
scripts/decomposition/generate-loose-foreign-key -c ci_job_token_project_scope_links
```

To swap only the `source_project_id` of `ci_job_token_project_scope_links` for the decomposed database, run:

```shell
scripts/decomposition/generate-loose-foreign-key -c ci_job_token_project_scope_links source_project_id
```

To match the exact name of a table or columns, you can make use of the regular expressions
position anchors `^` and `$`. For example, this command matches only the
foreign keys on the `events` table only, but not on the table
`incident_management_timeline_events`.

```shell
scripts/decomposition/generate-loose-foreign-key -n ^events$
```

To swap all the foreign keys (all having `_id` appended), but not create a new branch (only commit
the changes) and not create RSpec tests, run:

```shell
scripts/decomposition/generate-loose-foreign-key -c --no-branch --no-rspec _id
```

To swap all foreign keys referencing `projects`, but not create a new branch (only commit the
changes), run:

```shell
scripts/decomposition/generate-loose-foreign-key -c --no-branch projects
```

## Example migration and configuration

### Configure the loose foreign key

Loose foreign keys are defined in a YAML file. The configuration requires the
following information:

- Parent table name (`projects`)
- Child table name (`ci_pipelines`)
- The data cleanup method (`async_delete` or `async_nullify`)

The YAML file is located at `config/gitlab_loose_foreign_keys.yml`. The file groups
foreign key definitions by the name of the child table. The child table can have multiple loose
foreign key definitions, therefore we store them as an array.

Example definition:

```yaml
ci_pipelines:
  - table: projects
    column: project_id
    on_delete: async_delete
```

If the `ci_pipelines` key is already present in the YAML file, then a new entry can be added
to the array:

```yaml
ci_pipelines:
  - table: projects
    column: project_id
    on_delete: async_delete
  - table: another_table
    column: another_id
    on_delete: :async_nullify
```

### Track record changes

To know about deletions in the `projects` table, configure a `DELETE` trigger
using a [post-deployment migration](post_deployment_migrations.md). The
trigger needs to be configured only once. If the model already has at least one
`loose_foreign_key` definition, then this step can be skipped:

```ruby
class TrackProjectRecordChanges < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  def up
    track_record_deletions(:projects)
  end

  def down
    untrack_record_deletions(:projects)
  end
end
```

### Remove the foreign key

If there is an existing foreign key, then it can be removed from the database. This foreign key describes the link between the `projects` and `ci_pipelines` tables:

```sql
ALTER TABLE ONLY ci_pipelines
ADD CONSTRAINT fk_86635dbd80
FOREIGN KEY (project_id)
REFERENCES projects(id)
ON DELETE CASCADE;
```

The migration must run after the `DELETE` trigger is installed and the loose
foreign key definition is deployed. As such, it must be a
[post-deployment migration](post_deployment_migrations.md) dated after the migration for the
trigger. If the foreign key is deleted earlier, there is a good chance of
introducing data inconsistency which needs manual cleanup:

```ruby
class RemoveProjectsCiPipelineFk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:ci_pipelines, :projects, name: "fk_86635dbd80")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_pipelines, :projects, name: "fk_86635dbd80", column: :project_id, target_column: :id, on_delete: "cascade")
  end
end
```

At this point, the setup phase is concluded. The deleted `projects` records should be automatically
picked up by the scheduled cleanup worker job.

### Remove the loose foreign key

When the loose foreign key definition is no longer needed (parent table is removed, or FK is restored),
we need to remove the definition from the YAML file and ensure that we don't leave pending deleted
records in the database.

1. Remove the loose foreign key definition from the configuration (`config/gitlab_loose_foreign_keys.yml`).

The deletion tracking trigger needs to be removed only when the parent table no longer uses loose foreign keys.
If the model still has at least one `loose_foreign_key` definition remaining, then these steps can be skipped:

1. Remove the trigger from the parent table (if the parent table is still there).
1. Remove leftover deleted records from the `loose_foreign_keys_deleted_records` table.

Migration for removing the trigger:

```ruby
class UnTrackProjectRecordChanges < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  def up
    untrack_record_deletions(:projects)
  end

  def down
    track_record_deletions(:projects)
  end
end
```

With the trigger removal, we prevent further records to be inserted in the `loose_foreign_keys_deleted_records`
table however, there is still a chance for having leftover pending records in the table. These records
must be removed with an inline data migration.

```ruby
class RemoveLeftoverProjectDeletions < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    loop do
      result = execute <<~SQL
      DELETE FROM "loose_foreign_keys_deleted_records"
      WHERE
      ("loose_foreign_keys_deleted_records"."partition", "loose_foreign_keys_deleted_records"."id") IN (
        SELECT "loose_foreign_keys_deleted_records"."partition", "loose_foreign_keys_deleted_records"."id"
        FROM "loose_foreign_keys_deleted_records"
        WHERE
        "loose_foreign_keys_deleted_records"."fully_qualified_table_name" = 'public.projects' AND
        "loose_foreign_keys_deleted_records"."status" = 1
        LIMIT 100
      )
      SQL

      break if result.cmd_tuples == 0
    end
  end

  def down
    # no-op
  end
end
```

## Testing

The "`it has loose foreign keys`" shared example can be used to test the presence of the `ON DELETE` trigger and the
loose foreign key definitions.

Add to the model test file:

```ruby
it_behaves_like 'it has loose foreign keys' do
  let(:factory_name) { :project }
end
```

**After** [removing a foreign key](#remove-the-foreign-key),
use the "`cleanup by a loose foreign key`" shared example to test a child record's deletion or nullification
via the added loose foreign key:

```ruby
it_behaves_like 'cleanup by a loose foreign key' do
  let!(:model) { create(:ci_pipeline, user: create(:user)) }
  let!(:parent) { model.user }
end
```

## Caveats of loose foreign keys

### Record creation

The feature provides an efficient way of cleaning up associated records after the parent record is
deleted. Without foreign keys, it's the application's responsibility to validate if the parent record
exists when a new associated record is created.

A bad example: record creation with the given ID (`project_id` comes from user input).
In this example, nothing prevents us from passing a random project ID:

```ruby
Ci::Pipeline.create!(project_id: params[:project_id])
```

A good example: record creation with extra check:

```ruby
project = Project.find(params[:project_id])
Ci::Pipeline.create!(project_id: project.id)
```

### Association lookup

Consider the following HTTP request:

```plaintext
GET /projects/5/pipelines/100
```

The controller action ignores the `project_id` parameter and finds the pipeline using the ID:

```ruby
  def show
  # bad, avoid it
  pipeline = Ci::Pipeline.find(params[:id]) # 100
end
```

This endpoint still works when the parent `Project` model is deleted. This can be considered a
data leak which should not happen under typical circumstances:

```ruby
def show
  # good
  project = Project.find(params[:project_id])
  pipeline = project.pipelines.find(params[:pipeline_id]) # 100
end
```

NOTE:
This example is unlikely in GitLab, because we usually look up the parent models to perform
permission checks.

## A note on `dependent: :destroy` and `dependent: :nullify`

We considered using these Rails features as an alternative to foreign keys but there are several problems which include:

1. These run on a different connection in the context of a transaction [which we do not allow](multiple_databases.md#removing-cross-database-transactions).
1. These can lead to severe performance degradation as we load all records from PostgreSQL, loop over them in Ruby, and call individual `DELETE` queries.
1. These can miss data as they only cover the case when the `destroy` method is called directly on the model. There are other cases including `delete_all` and cascading deletes from another parent table that could mean these are missed.

For non-trivial objects that need to clean up data outside the
database (for example, object storage) where you might wish to use `dependent: :destroy`,
see alternatives in
[Avoid `dependent: :nullify` and `dependent: :destroy` across databases](multiple_databases.md#avoid-dependent-nullify-and-dependent-destroy-across-databases).

## Update target column to a value

A loose foreign key might be used to update a target column to a value when an
entry in parent table is deleted.

It's important to add an index (if it doesn't exist yet) on
(`column`, `target_column`) to avoid any performance issues.
Any index starting with these two columns will work.

The configuration requires additional information:

- Column to be updated (`target_column`)
- Value to be set in the target column (`target_value`)

Example definition:

```yaml
packages:
  - table: projects
    column: project_id
    on_delete: update_column_to
    target_column: status
    target_value: 4
```

## Risks of loose foreign keys and possible mitigations

In general, the loose foreign keys architecture is eventually consistent and
the cleanup latency might lead to problems visible to GitLab users or
operators. We consider the tradeoff as acceptable, but there might be
cases where the problems are too frequent or too severe, and we must
implement a mitigation strategy. A general mitigation strategy might be to have
an "urgent" queue for cleanup of records that have higher impact with a delayed
cleanup.

Below are some more specific examples of problems that might occur and how we
might mitigate them. In all the listed cases we might still consider the problem
described to be low risk and low impact, and in that case we would choose to not
implement any mitigation.

### The record should be deleted but it shows up in a view

This hypothetical example might happen with a foreign key like:

```sql
ALTER TABLE ONLY vulnerability_occurrence_pipelines
    ADD CONSTRAINT fk_rails_6421e35d7d FOREIGN KEY (pipeline_id) REFERENCES ci_pipelines(id) ON DELETE CASCADE;
```

In this example we expect to delete all associated `vulnerability_occurrence_pipelines` records
whenever we delete the `ci_pipelines` record associated with them. In this case
you might end up with some vulnerability page in GitLab which shows an occurrence
of a vulnerability. However, when you try to select a link to the pipeline, you get
a 404, because the pipeline is deleted. Then, when you navigate back you might find the
occurrence has disappeared too.

**Mitigation**

When rendering the vulnerability occurrences on the vulnerability page we could
try to load the corresponding pipeline and choose to skip displaying that
occurrence if pipeline is not found.

### The deleted parent record is needed to render a view and causes a `500` error

This hypothetical example might happen with a foreign key like:

```sql
ALTER TABLE ONLY vulnerability_occurrence_pipelines
    ADD CONSTRAINT fk_rails_6421e35d7d FOREIGN KEY (pipeline_id) REFERENCES ci_pipelines(id) ON DELETE CASCADE;
```

In this example we expect to delete all associated `vulnerability_occurrence_pipelines` records
whenever we delete the `ci_pipelines` record associated with them. In this case
you might end up with a vulnerability page in GitLab which shows an "occurrence"
of a vulnerability. However, when rendering the occurrence we try to load, for example,
`occurrence.pipeline.created_at`, which causes a 500 for the user.

**Mitigation**

When rendering the vulnerability occurrences on the vulnerability page we could
try to load the corresponding pipeline and choose to skip displaying that
occurrence if pipeline is not found.

### The deleted parent record is accessed in a Sidekiq worker and causes a failed job

This hypothetical example might happen with a foreign key like:

```sql
ALTER TABLE ONLY vulnerability_occurrence_pipelines
    ADD CONSTRAINT fk_rails_6421e35d7d FOREIGN KEY (pipeline_id) REFERENCES ci_pipelines(id) ON DELETE CASCADE;
```

In this example we expect to delete all associated `vulnerability_occurrence_pipelines` records
whenever we delete the `ci_pipelines` record associated with them. In this case
you might end up with a Sidekiq worker that is responsible for processing a
vulnerability and looping over all occurrences causing a Sidekiq job to fail if
it executes `occurrence.pipeline.created_at`.

**Mitigation**

When looping through the vulnerability occurrences in the Sidekiq worker, we
could try to load the corresponding pipeline and choose to skip processing that
occurrence if pipeline is not found.

## Architecture

The loose foreign keys feature is implemented within the `LooseForeignKeys` Ruby namespace. The
code is isolated from the core application code and theoretically, it could be a standalone library.

The feature is invoked solely in the [`LooseForeignKeys::CleanupWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/workers/loose_foreign_keys/cleanup_worker.rb) worker class. The worker is scheduled via a
cron job where the schedule depends on the configuration of the GitLab instance.

- Non-decomposed GitLab (1 database): invoked every minute.
- Decomposed GitLab (2 databases, CI and Main): invoked every minute, cleaning up one database
  at a time. For example, the cleanup worker for the main database runs every two minutes.

To avoid lock contention and the processing of the same database rows, the worker does not run
parallel. This behavior is ensured with a Redis lock.

**Record cleanup procedure:**

1. Acquire the Redis lock.
1. Determine which database to clean up.
1. Collect all database tables where the deletions are tracked (parent tables).
   - This is achieved by reading the `config/gitlab_loose_foreign_keys.yml` file.
   - A table is considered "tracked" when a loose foreign key definition exists for the table and
     the `DELETE` trigger is installed.
1. Cycle through the tables with an infinite loop.
1. For each table, load a batch of deleted parent records to clean up.
1. Depending on the YAML configuration, build `DELETE` or `UPDATE` (nullify) queries for the
   referenced child tables.
1. Invoke the queries.
1. Repeat until all child records are cleaned up or the maximum limit is reached.
1. Remove the deleted parent records when all child records are cleaned up.

### Database structure

The feature relies on triggers installed on the parent tables. When a parent record is deleted,
the trigger automatically inserts a new record into the `loose_foreign_keys_deleted_records`
database table.

The inserted record stores the following information about the deleted record:

- `fully_qualified_table_name`: name of the database table where the record was located.
- `primary_key_value`: the ID of the record, the value is present in the child tables as
  the foreign key value. At the moment, composite primary keys are not supported, the parent table
  must have an `id` column.
- `status`: defaults to pending, represents the status of the cleanup process.
- `consume_after`: defaults to the current time.
- `cleanup_attempts`: defaults to 0. The number of times the worker tried to clean up this record.
  A non-zero number would mean that this record has many child records and cleaning it up requires
  several runs.

#### Database decomposition

The `loose_foreign_keys_deleted_records` table exists on both database servers (`ci` and `main`)
after the [database decomposition](https://gitlab.com/groups/gitlab-org/-/epics/6168). The worker
ill determine which parent tables belong to which database by reading the
`lib/gitlab/database/gitlab_schemas.yml` YAML file.

Example:

- Main database tables
  - `projects`
  - `namespaces`
  - `merge_requests`
- Ci database tables
  - `ci_builds`
  - `ci_pipelines`

When the worker is invoked for the `ci` database, the worker loads deleted records only from the
`ci_builds` and `ci_pipelines` tables. During the cleanup process, `DELETE` and `UPDATE` queries
mostly run on tables located in the Main database. In this example, one `UPDATE` query
nullifies the `merge_requests.head_pipeline_id` column.

#### Database partitioning

Due to the large volume of inserts the database table receives daily, a special partitioning
strategy was implemented to address data bloat concerns. Originally, the
[time-decay](https://handbook.gitlab.com/handbook/company/working-groups/database-scalability/time-decay/)
strategy was considered for the feature but due to the large data volume we decided to implement a
new strategy.

A deleted record is considered fully processed when all its direct children records have been
cleaned up. When this happens, the loose foreign key worker updates the `status` column of
the deleted record. After this step, the record is no longer needed.

The sliding partitioning strategy provides an efficient way of cleaning up old, unused data by
adding a new database partition and removing the old one when certain conditions are met.
The `loose_foreign_keys_deleted_records` database table is list partitioned where most of the
time there is only one partition attached to the table.

```sql
                                                             Partitioned table "public.loose_foreign_keys_deleted_records"
           Column           |           Type           | Collation | Nullable |                            Default                             | Storage  | Stats target | Description
----------------------------+--------------------------+-----------+----------+----------------------------------------------------------------+----------+--------------+-------------
 id                         | bigint                   |           | not null | nextval('loose_foreign_keys_deleted_records_id_seq'::regclass) | plain    |              |
 partition                  | bigint                   |           | not null | 84                                                             | plain    |              |
 primary_key_value          | bigint                   |           | not null |                                                                | plain    |              |
 status                     | smallint                 |           | not null | 1                                                              | plain    |              |
 created_at                 | timestamp with time zone |           | not null | now()                                                          | plain    |              |
 fully_qualified_table_name | text                     |           | not null |                                                                | extended |              |
 consume_after              | timestamp with time zone |           |          | now()                                                          | plain    |              |
 cleanup_attempts           | smallint                 |           |          | 0                                                              | plain    |              |
Partition key: LIST (partition)
Indexes:
    "loose_foreign_keys_deleted_records_pkey" PRIMARY KEY, btree (partition, id)
    "index_loose_foreign_keys_deleted_records_for_partitioned_query" btree (partition, fully_qualified_table_name, consume_after, id) WHERE status = 1
Check constraints:
    "check_1a541f3235" CHECK (char_length(fully_qualified_table_name) <= 150)
Partitions: gitlab_partitions_dynamic.loose_foreign_keys_deleted_records_84 FOR VALUES IN ('84')
```

The `partition` column controls the insert direction, the `partition` value determines which
partition gets the deleted rows inserted via the trigger. Notice that the default value of
the `partition` table matches with the value of the list partition (84). In `INSERT` query
within the trigger the value of the `partition` is omitted, the trigger always relies on the
default value of the column.

Example `INSERT` query for the trigger:

```sql
INSERT INTO loose_foreign_keys_deleted_records
(fully_qualified_table_name, primary_key_value)
SELECT TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME, old_table.id FROM old_table;
```

The partition "sliding" process is controlled by two, regularly executed callbacks. These
callbacks are defined within the `LooseForeignKeys::DeletedRecord` model.

The `next_partition_if` callback controls when to create a new partition. A new partition is
created when the current partition has at least one record older than 24 hours. A new partition
is added by the [`PartitionManager`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/database/partitioning/partition_manager.rb)
using the following steps:

1. Create a new partition, where the `VALUE` for the partition is `CURRENT_PARTITION + 1`.
1. Update the default value of the `partition` column to `CURRENT_PARTITION + 1`.

With these steps, all new `INSERT` queries via the triggers end up in the new partition. At this point,
the database table has two partitions.

The `detach_partition_if` callback determines if the old partitions can be detached from the table.
A partition is detachable if there are no pending (unprocessed) records in the partition
(`status = 1`). The detached partitions are available for some time, you can see the list
detached partitions in the `detached_partitions` table:

```sql
select * from detached_partitions;
```

#### Cleanup queries

The `LooseForeignKeys::CleanupWorker` has its database query builder which depends on `Arel`.
The feature doesn't reference any application-specific `ActiveRecord` models to avoid unexpected
side effects. The database queries are batched, which means that several parent records are being
cleaned up at the same time.

Example `DELETE` query:

```sql
DELETE
FROM "merge_request_metrics"
WHERE ("merge_request_metrics"."id") IN
  (SELECT "merge_request_metrics"."id"
    FROM "merge_request_metrics"
    WHERE "merge_request_metrics"."pipeline_id" IN (1, 2, 10, 20)
    LIMIT 1000 FOR UPDATE SKIP LOCKED)
```

The primary key values of the parent records are 1, 2, 10, and 20.

Example `UPDATE` (nullify) query:

```sql
UPDATE "merge_requests"
SET "head_pipeline_id" = NULL
WHERE ("merge_requests"."id") IN
    (SELECT "merge_requests"."id"
     FROM "merge_requests"
     WHERE "merge_requests"."head_pipeline_id" IN (3, 4, 30, 40)
     LIMIT 500 FOR UPDATE SKIP LOCKED)
```

These queries are batched, which means that in many cases, several invocations are needed to clean
up all associated child records.

The batching is implemented with loops, the processing stops when all associated child records
are cleaned up or the limit is reached.

```ruby
loop do
  modification_count = process_batch_with_skip_locked

  break if modification_count == 0 || over_limit?
end

loop do
  modification_count = process_batch

  break if modification_count == 0 || over_limit?
end
```

The loop-based batch processing is preferred over `EachBatch` for the following reasons:

- The records in the batch are modified, so the next batch contains different records.
- There is always an index on the foreign key column however, the column is usually not unique.
  `EachBatch` requires a unique column for the iteration.
- The record order doesn't matter for the cleanup.

Notice that we have two loops. The initial loop processes records with the `SKIP LOCKED` clause.
The query skips rows that are locked by other application processes. This ensures that the
cleanup worker is less likely to become blocked. The second loop executes the database
queries without `SKIP LOCKED` to ensure that all records have been processed.

#### Processing limits

A constant, large volume of record updates or deletions can cause incidents and affect the
availability of GitLab:

- Increased table bloat.
- Increased number of pending WAL files.
- Busy tables, difficulty when acquiring locks.

To mitigate these issues, several limits are applied when the worker runs.

- Each query has `LIMIT`, a query cannot process an unbounded number of rows.
- The maximum number of record deletions and record updates is limited.
- The maximum runtime (30 seconds) for the database queries is limited.

The limit rules are implemented in the `LooseForeignKeys::ModificationTracker` class. When one of
the limits (record modification count, time limit) is reached the processing is stopped
immediately. After some time, the next scheduled worker continues the cleanup process.

#### Performance characteristics

The database trigger on the parent tables **decreases** the record deletion speed. Each
statement that removes rows from the parent table invokes the trigger to insert records
into the `loose_foreign_keys_deleted_records` table.

The queries within the cleanup worker are fairly efficient index scans, with limits in place
they're unlikely to affect other parts of the application.

The database queries are not running in transaction, when an error happens for example a statement
timeout or a worker crash, the next job continues the processing.

## Troubleshooting

### Accumulation of deleted records

There can be cases where the workers need to process an unusually large amount of data. This can
happen under typical usage, for example when a large project or group is deleted. In this scenario,
there can be several million rows to be deleted or nullified. Due to the limits enforced by the
worker, processing this data takes some time.

When cleaning up "heavy-hitters", the feature ensures fair processing by rescheduling larger
batches for later. This gives time for other deleted records to be processed.

For example, a project with millions of `ci_builds` records is deleted. The `ci_builds` records
is deleted by the loose foreign keys feature.

1. The cleanup worker is scheduled and picks up a batch of deleted `projects` records. The large
   project is part of the batch.
1. Deletion of the orphaned `ci_builds` rows has started.
1. The time limit is reached, but the cleanup is not complete.
1. The `cleanup_attempts` column is incremented for the deleted records.
1. Go to step 1. The next cleanup worker continues the cleanup.
1. When the `cleanup_attempts` reaches 3, the batch is re-scheduled 10 minutes later by updating
   the `consume_after` column.
1. The next cleanup worker processes a different batch.

We have Prometheus metrics in place to monitor the deleted record cleanup:

- `loose_foreign_key_processed_deleted_records`: Number of processed deleted records. When large
  cleanup happens, this number would decrease.
- `loose_foreign_key_incremented_deleted_records`: Number of deleted records which were not
  finished processing. The `cleanup_attempts` column was incremented.
- `loose_foreign_key_rescheduled_deleted_records`: Number of deleted records that had to be
  rescheduled at a later time after 3 cleanup attempts.

Example PromQL query:

```plaintext
loose_foreign_key_rescheduled_deleted_records{env="gprd", table="ci_runners"}
```

Another way to look at the situation is by running a database query. This query gives the exact
counts of the unprocessed records:

```sql
SELECT partition, fully_qualified_table_name, count(*)
FROM loose_foreign_keys_deleted_records
WHERE
status = 1
GROUP BY 1, 2;
```

Example output:

```sql
 partition | fully_qualified_table_name | count
-----------+----------------------------+-------
        87 | public.ci_builds           |   874
        87 | public.ci_job_artifacts    |  6658
        87 | public.ci_pipelines        |   102
        87 | public.ci_runners          |   111
        87 | public.merge_requests      |   255
        87 | public.namespaces          |    25
        87 | public.projects            |     6
```

The query includes the partition number which can be useful to detect if the cleanup process is
significantly lagging behind. When multiple different partition values are present in the list
that means the cleanup of some deleted records didn't finish in several days (1 new partition
is added every day).

Steps to diagnose the problem:

- Check which records are accumulating.
- Try to get an estimate of the number of remaining records.
- Looking into the worker performance stats (Kibana or Grafana).

Possible solutions:

- Short-term: increase the batch sizes.
- Long-term: invoke the worker more frequently. Parallelize the worker

For a one-time fix, we can run the cleanup worker several times from the rails console. The worker
can run in parallel however, this can introduce lock contention and it could increase the worker
runtime.

```ruby
LooseForeignKeys::CleanupWorker.new.perform
```

When the cleanup is done, the older partitions are automatically detached by the
`PartitionManager`.

### PartitionManager bug

NOTE:
This issue happened in the past on Staging and it has been mitigated.

When adding a new partition, the default value of the `partition` column is also updated. This is
a schema change that is executed in the same transaction as the new partition creation. It's highly
unlikely that the `partition` column goes outdated.

However, if this happens then this can cause application-wide incidents because the `partition`
value points to a partition that doesn't exist. Symptom: deletion of records from tables where the
`DELETE` trigger is installed fails.

```sql
\d+ loose_foreign_keys_deleted_records;

           Column           |           Type           | Collation | Nullable |                            Default                             | Storage  | Stats target | Description
----------------------------+--------------------------+-----------+----------+----------------------------------------------------------------+----------+--------------+-------------
 id                         | bigint                   |           | not null | nextval('loose_foreign_keys_deleted_records_id_seq'::regclass) | plain    |              |
 partition                  | bigint                   |           | not null | 4                                                              | plain    |              |
 primary_key_value          | bigint                   |           | not null |                                                                | plain    |              |
 status                     | smallint                 |           | not null | 1                                                              | plain    |              |
 created_at                 | timestamp with time zone |           | not null | now()                                                          | plain    |              |
 fully_qualified_table_name | text                     |           | not null |                                                                | extended |              |
 consume_after              | timestamp with time zone |           |          | now()                                                          | plain    |              |
 cleanup_attempts           | smallint                 |           |          | 0                                                              | plain    |              |
Partition key: LIST (partition)
Indexes:
    "loose_foreign_keys_deleted_records_pkey" PRIMARY KEY, btree (partition, id)
    "index_loose_foreign_keys_deleted_records_for_partitioned_query" btree (partition, fully_qualified_table_name, consume_after, id) WHERE status = 1
Check constraints:
    "check_1a541f3235" CHECK (char_length(fully_qualified_table_name) <= 150)
Partitions: gitlab_partitions_dynamic.loose_foreign_keys_deleted_records_3 FOR VALUES IN ('3')
```

Check the default value of the `partition` column and compare it with the available partitions
(4 vs 3). The partition with the value of 4 does not exist. To mitigate the problem an emergency
schema change is required:

```sql
ALTER TABLE loose_foreign_keys_deleted_records ALTER COLUMN partition SET DEFAULT 3;
```

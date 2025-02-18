---
stage: Data Access
group: Database
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Migrations for Multiple databases
---

This document describes how to properly write database migrations
for [the decomposed GitLab application using multiple databases](https://gitlab.com/groups/gitlab-org/-/epics/6168).
For more information, see [Multiple databases](multiple_databases.md).

The design for multiple databases (except for the Geo database) assumes
that all decomposed databases have **the same structure** (for example, schema), but **the data is different** in each database. This means that some tables do not contain data on each database.

## Operations

Depending on the used constructs, we can classify migrations to be either:

1. Modifying structure ([DDL - Data Definition Language](https://www.postgresql.org/docs/current/ddl.html)) (for example, `ALTER TABLE`).
1. Modifying data ([DML - Data Manipulation Language](https://www.postgresql.org/docs/current/dml.html)) (for example, `UPDATE`).
1. Performing [other queries](https://www.postgresql.org/docs/current/queries.html) (for example, `SELECT`) that are treated as **DML** for the purposes of our migrations.

**The usage of `Gitlab::Database::Migration[2.0]` requires migrations to always be of a single purpose**.
Migrations cannot mix **DDL** and **DML** changes as the application requires the structure
(as described by `db/structure.sql`) to be exactly the same across all decomposed databases.

### Data Definition Language (DDL)

The DDL migrations are all migrations that:

1. Create or drop a table (for example, `create_table`).
1. Add or remove an index (for example, `add_index`, `add_concurrent_index`).
1. Add or remove a foreign key (for example `add_foreign_key`, `add_concurrent_foreign_key`).
1. Add or remove a column with or without a default value (for example, `add_column`).
1. Create or drop trigger functions (for example, `create_trigger_function`).
1. Attach or detach triggers from tables (for example, `track_record_deletions`, `untrack_record_deletions`).
1. Prepare or not asynchronous indexes (for example, `prepare_async_index`, `unprepare_async_index_by_name`).
1. Truncate a table (for example using the `truncate_tables!` helper method).

As such DDL migrations **CANNOT**:

1. Read or modify data in any form, via SQL statements or ActiveRecord models.
1. Update column values (for example, `update_column_in_batches`).
1. Schedule background migrations (for example, `queue_background_migration_jobs_by_range_at_intervals`).
1. Read the state of feature flags since they are stored in `main:` (a `features` and `feature_gates`).
1. Read application settings (as settings are stored in `main:`).

As the majority of migrations in the GitLab codebase are of the DDL-type,
this is also the default mode of operation and requires no further changes
to the migrations files.

#### Example: perform DDL on all databases

Example migration adding a concurrent index that is treated as change of the structure (DDL)
that is executed on all configured databases.

```ruby
class AddUserIdAndStateIndexToMergeRequestReviewers < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_on_merge_request_reviewers_user_id_and_state'

  def up
    add_concurrent_index :merge_request_reviewers, [:user_id, :state], where: 'state = 2', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_request_reviewers, INDEX_NAME
  end
end
```

#### Example: Add a new table to store in a single database

1. Add the table to the [database dictionary](database_dictionary.md) in [`db/docs/`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/db/docs):

   ```yaml
   table_name: ssh_signatures
   description: Description example
   introduced_by_url: Merge request link
   milestone: Milestone example
   feature_categories:
   - Feature category example
   classes:
   - Class example
   gitlab_schema: gitlab_main
   ```

1. Create the table in a schema migration:

   ```ruby
   class CreateSshSignatures < Gitlab::Database::Migration[2.1]
     def change
       create_table :ssh_signatures do |t|
         t.timestamps_with_timezone null: false
         t.bigint :project_id, null: false, index: true
         t.bigint :key_id, null: false, index: true
         t.integer :verification_status, default: 0, null: false, limit: 2
         t.binary :commit_sha, null: false, index: { unique: true }
       end
     end
   end
   ```

### Data Manipulation Language (DML)

The DML migrations are all migrations that:

1. Read data via SQL statements (for example, `SELECT * FROM projects WHERE id=1`).
1. Read data via ActiveRecord models (for example, `User < MigrationRecord`).
1. Create, update or delete data via ActiveRecord models (for example, `User.create!(...)`).
1. Create, update or delete data via SQL statements (for example, `DELETE FROM projects WHERE id=1`).
1. Update columns in batches (for example, `update_column_in_batches(:projects, :archived, true)`).
1. Schedule background migrations (for example, `queue_background_migration_jobs_by_range_at_intervals`).
1. Access application settings (for example, `ApplicationSetting.last` if run for `main:` database).
1. Read and modify feature flags if run for the `main:` database.

The DML migrations **CANNOT**:

1. Make any changes to DDL since this breaks the rule of keeping `structure.sql` coherent across
   all decomposed databases.
1. **Read data from another database**.

To indicate the `DML` migration type, a migration must use the `restrict_gitlab_migration gitlab_schema:`
syntax in a migration class. This marks the given migration as DML and restricts access to it.

#### Example: perform DML only in context of the database containing the given `gitlab_schema`

Example migration updating `archived` column of `projects` that is executed
only for the database containing `gitlab_main` schema.

```ruby
class UpdateProjectsArchivedState < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    update_column_in_batches(:projects, :archived, true) do |table, query|
      query.where(table[:archived].eq(false)) # rubocop:disable CodeReuse/ActiveRecord
    end
  end

  def down
    # no-op
  end
end
```

#### Example: usage of `ActiveRecord` classes

A migration using `ActiveRecord` class to perform data manipulation
must use the `MigrationRecord` class. This class is guaranteed to provide
a correct connection in a context of a given migration.

Underneath the `MigrationRecord == ActiveRecord::Base`, as once the `db:migrate`
runs, it switches the active connection of `ActiveRecord::Base.establish_connection :ci`.
To avoid confusion to using the `ActiveRecord::Base`, `MigrationRecord` is required.

This implies that DML migrations are forbidden to read data from other
databases. For example, running migration in context of `ci:` and reading feature flags
from `main:`, as no established connection to another database is present.

```ruby
class UpdateProjectsArchivedState < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class Project < MigrationRecord
  end

  def up
    Project.where(archived: false).each_batch of |batch|
      batch.update_all(archived: true)
    end
  end

  def down
  end
end
```

### The special purpose of `gitlab_shared`

As described in [`gitlab_schema`](multiple_databases.md#the-special-purpose-of-gitlab_shared),
the `gitlab_shared` tables are allowed to contain data across all databases. This implies
that such migrations should run across all databases to modify structure (DDL) or modify data (DML).

As such migrations accessing `gitlab_shared` do not need to use `restrict_gitlab_migration gitlab_schema:`,
migrations without restriction run across all databases and are allowed to modify data on each of them.
If the `restrict_gitlab_migration gitlab_schema:` is specified, the `DML` migration
runs only in a context of a database containing the given `gitlab_schema`.

#### Example: run DML `gitlab_shared` migration on all databases

Example migration updating `loose_foreign_keys_deleted_records` table
that is marked in `lib/gitlab/database/gitlab_schemas.yml` as `gitlab_shared`.

This migration is executed across all configured databases.

```ruby
class DeleteAllLooseForeignKeyRecords < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    execute("DELETE FROM loose_foreign_keys_deleted_records")
  end

  def down
    # no-op
  end
end
```

#### Example: run DML `gitlab_shared` only on the database containing the given `gitlab_schema`

Example migration updating `loose_foreign_keys_deleted_records` table
that is marked in `db/docs/loose_foreign_keys_deleted_records.yml` as `gitlab_shared`.

This migration since it configures restriction on `gitlab_ci` is executed only
in context of database containing `gitlab_ci` schema.

```ruby
class DeleteCiBuildsLooseForeignKeyRecords < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    execute("DELETE FROM loose_foreign_keys_deleted_records WHERE fully_qualified_table_name='ci_builds'")
  end

  def down
    # no-op
  end
end
```

### The behavior of skipping migrations

The only migrations that are skipped are the ones performing **DML** changes.
The **DDL** migrations are **always and unconditionally** executed.

The implemented [solution](https://gitlab.com/gitlab-org/gitlab/-/issues/355014#solution-2-use-database_tasks)
uses the `database_tasks:` as a way to indicate which additional database configurations
(in `config/database.yml`) share the same primary database. The database configurations
marked with `database_tasks: false` are exempt from executing `db:migrate` for those
database configurations.

If database configurations do not share databases (all do have `database_tasks: true`),
each migration runs for every database configuration:

1. The DDL migration applies all structure changes on all databases.
1. The DML migration runs only in the context of a database containing the given `gitlab_schema:`.
1. If the DML migration is not eligible to run, it is skipped. It's still
   marked as executed in `schema_migrations`. While running `db:migrate`, the skipped
   migration outputs `Current migration is skipped since it modifies 'gitlab_ci' which is outside of 'gitlab_main, gitlab_shared`.

To prevent loss of migrations if the `database_tasks: false` is configured, a dedicated
Rake task is used [`gitlab:db:validate_config`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/83118).
The `gitlab:db:validate_config` validates the correctness of `database_tasks:` by checking database identifiers
of each underlying database configuration. The ones that share the database are required to have
the `database_tasks: false` set. `gitlab:db:validate_config` always runs before `db:migrate`.

## Validation

Validation in a nutshell uses [`pg_query`](https://github.com/pganalyze/pg_query) to analyze
each query and classify tables with information from [`db/docs/`](database_dictionary.md).
The migration is skipped if the specified `gitlab_schema` is outside of a list of schemas
managed by a given database connection (`Gitlab::Database::gitlab_schemas_for_connection`).

The `Gitlab::Database::Migration[2.0]` includes `Gitlab::Database::MigrationHelpers::RestrictGitlabSchema`
which extends the `#migrate` method. For the duration of a migration a dedicated query analyzer
is installed `Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas` that accepts
a list of allowed schemas as defined by `restrict_gitlab_migration:`. If the executed query
is outside of allowed schemas, it raises an exception.

## Exceptions

Depending on misuse or lack of `restrict_gitlab_migration` various exceptions can be raised
as part of the migration run and prevent the migration from being completed.

### Exception 1: migration running in DDL mode does DML select

```ruby
class UpdateProjectsArchivedState < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  # Missing:
  # restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    update_column_in_batches(:projects, :archived, true) do |table, query|
      query.where(table[:archived].eq(false)) # rubocop:disable CodeReuse/ActiveRecord
    end
  end

  def down
    # no-op
  end
end
```

```plaintext
Select/DML queries (SELECT/UPDATE/DELETE) are disallowed in the DDL (structure) mode
Modifying of 'projects' (gitlab_main) with 'SELECT * FROM projects...
```

The current migration do not use `restrict_gitlab_migration`. The lack indicates a migration
running in **DDL** mode, but the executed payload appears to be reading data from `projects`.

**The solution** is to add `restrict_gitlab_migration gitlab_schema: :gitlab_main`.

### Exception 2: migration running in DML mode changes the structure

```ruby
class AddUserIdAndStateIndexToMergeRequestReviewers < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  # restrict_gitlab_migration if defined indicates DML, it should be removed
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  INDEX_NAME = 'index_on_merge_request_reviewers_user_id_and_state'

  def up
    add_concurrent_index :merge_request_reviewers, [:user_id, :state], where: 'state = 2', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_request_reviewers, INDEX_NAME
  end
end
```

```plaintext
DDL queries (structure) are disallowed in the Select/DML (SELECT/UPDATE/DELETE) mode.
Modifying of 'merge_request_reviewers' with 'CREATE INDEX...
```

The current migration do use `restrict_gitlab_migration`. The presence indicates **DML** mode,
but the executed payload appears to be doing structure changes (DDL).

**The solution** is to remove `restrict_gitlab_migration gitlab_schema: :gitlab_main`.

### Exception 3: migration running in DML mode accesses data from a table in another schema

```ruby
class UpdateProjectsArchivedState < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  # Since it modifies `projects` it should use `gitlab_main`
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    update_column_in_batches(:projects, :archived, true) do |table, query|
      query.where(table[:archived].eq(false)) # rubocop:disable CodeReuse/ActiveRecord
    end
  end

  def down
    # no-op
  end
end
```

```plaintext
Select/DML queries (SELECT/UPDATE/DELETE) do access 'projects' (gitlab_main) " \
which is outside of list of allowed schemas: 'gitlab_ci'
```

The current migration do restrict the migration to `gitlab_ci`, but appears to modify
data in `gitlab_main`.

**The solution** is to change `restrict_gitlab_migration gitlab_schema: :gitlab_ci`.

### Exception 4: mixing DDL and DML mode

```ruby
class UpdateProjectsArchivedState < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  # This migration is invalid regardless of specification
  # as it cannot modify structure and data at the same time
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    add_concurrent_index :merge_request_reviewers, [:user_id, :state], where: 'state = 2', name: 'index_on_merge_request_reviewers'
    update_column_in_batches(:projects, :archived, true) do |table, query|
      query.where(table[:archived].eq(false)) # rubocop:disable CodeReuse/ActiveRecord
    end
  end

  def down
    # no-op
  end
end
```

The migrations mixing **DDL** and **DML** depending on ordering of operations raises
one of the prior exceptions.

## Upcoming changes on multiple database migrations

The `restrict_gitlab_migration` using `gitlab_schema:` is considered as a first iteration
of this feature for running migrations selectively depending on a context. It is possible
to add additional restrictions to DML-only migrations (as the structure coherency is likely
to stay as-is until further notice) to restrict when they run.

A Potential extension is to limit running DML migration only to specific environments:

```ruby
restrict_gitlab_migration gitlab_schema: :gitlab_main, gitlab_env: :gitlab_com
```

## Background migrations

When you use:

- Background migrations with `track_jobs` set to `true` or
- Batched background migrations

The migration has to write to a jobs table. All of the
jobs tables used by background migrations are marked as `gitlab_shared`.
You can use these migrations when migrating tables in any database.

However, when queuing the batches, you must set `restrict_gitlab_migration` based on the
table you are iterating over. If you are updating all `projects`, for example, then you would set
`restrict_gitlab_migration gitlab_schema: :gitlab_main`. If, however, you are
updating all `ci_pipelines`, you would set
`restrict_gitlab_migration gitlab_schema: :gitlab_ci`.

As with all DML migrations, you cannot query another database outside of
`restrict_gitlab_migration` or `gitlab_shared`. If you need to query another database,
separate the migrations.

Because the actual migration logic (not the queueing step) for background
migrations runs in a Sidekiq worker, the logic can perform DML queries on
tables in any database, just like any ordinary Sidekiq worker can.

## How to determine `gitlab_schema` for a given table

See [database dictionary](database_dictionary.md).

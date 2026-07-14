---
source_checksum: e0fc1e17498d3165
distilled_at_sha: f22602e37afb92eb7028b601a922ebde417df6e4
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

> **Prerequisite:** If you haven't already, also read .ai/principles/distilled/database-fundamentals.md - it contains foundational rules that apply to all database work.

# Database Migrations Principles

## Checklist

### Migration Type Selection

- Choose regular schema migrations (`db/migrate`) for schema changes critical to application speed or behavior that complete in ≤ 3 minutes
- Choose post-deployment migrations (`db/post_migrate`) for non-critical schema changes (column removals, non-critical indexes) and data migrations completing in ≤ 10 minutes
- Use batched background migrations for data migrations exceeding 10 minutes; DO NOT use them to change the schema
- DO NOT use post-deployment migrations for `create_table` or `add_column` operations — these must be regular schema migrations
- Add a feature flag and use a post-deployment migration when a regular migration would be unacceptably slow
- Specify the correct `milestone` on every new migration (required since GitLab 16.6)
- Before adding new columns or indexes to tables exceeding size thresholds, review the [large tables limitations](https://docs.gitlab.com/development/database/large_tables_limitations/)

### Migration Class and Helpers

- Inherit from `Gitlab::Database::Migration[<latest_version>]` (e.g., `[2.1]`) — DO NOT include `Gitlab::Database::MigrationHelpers` directly
- Use the latest version of `Gitlab::Database::Migration` (look up `Gitlab::Database::Migration::MIGRATION_CLASSES`)
- DO NOT depend on GitLab application code in migrations; copy needed logic directly into the migration to keep it forward-compatible
- When using models in migrations, define them locally inheriting from `MigrationRecord` and set `self.table_name` explicitly
- Call `reset_column_information` on any model before using it after a schema change in the same migration run

### Reversibility

- Ensure every migration has a working `down` method
- When a data migration cannot be reversed, include a `down` method with a `# no-op` comment explaining why

### Transactions and Locking

- Use `disable_ddl_transaction!` when using `add_concurrent_index`, `add_concurrent_foreign_key`, or any operation that must run outside a single transaction
- Use `with_lock_retries` for DDL on [high-traffic tables](https://gitlab.com/gitlab-org/gitlab/-/blob/master/rubocop/rubocop-migrations.yml) to avoid lock contention
- DO NOT use `with_lock_retries` inside the `change` method — define explicit `up`/`down` methods
- DO NOT use PostgreSQL subtransactions; use multiple separate transactions instead
- When acquiring multiple table locks, lock in parent-to-child order to avoid deadlocks
- Create only one foreign key per transaction; use separate migrations for each FK when creating a table with multiple foreign keys
- Batch DML operations (INSERT/UPDATE/DELETE) on large datasets using `each_batch_range` or batched background migrations

### Indexes

- Use `add_concurrent_index` (with `disable_ddl_transaction!`) for adding indexes on non-empty tables
- Use `remove_concurrent_index` (with `disable_ddl_transaction!`) for removing indexes on non-empty tables
- Use `remove_index` in a single-transaction migration only for tables with fewer than 1,000 records
- Test for index existence by name, not by column list, when conditional logic depends on an index
- When `db:gitlabcom-database-testing` reports index creation exceeding 20 minutes, create the index asynchronously
- Truncate long index names: prefix with `i_` instead of `index_`, skip redundant prefixes, or use a purpose-based name

### Foreign Keys

- Use `add_concurrent_foreign_key` for adding foreign keys (has lock retries built in)
- Use `with_lock_retries` when removing foreign keys on high-traffic tables
- When removing a FK on a table with heavy write patterns, explicitly lock tables in parent-to-child order before removal
- For high-traffic or partitioned tables, separate FK creation (`validate: false`) and validation (`prepare_async_foreign_key_validation`) across different migrations

### Avoiding Downtime

- Follow the 3-release process for dropping columns: ignore (M) → drop (M+1) → remove ignore rule (M+2)
- DO NOT ignore and drop a column in the same release
- Add `ignore_column` with `remove_with` and `remove_after` attributes when ignoring a column
- If the model exists in both CE and EE, add `ignore_column` to the CE model
- When a column is referenced by a database view, also add `ignore_columns` to the corresponding view-backed model class
- Use `rename_column_concurrently` + `cleanup_concurrent_column_rename` (across two migrations) for zero-downtime column renames
- Use `change_column_type_concurrently` + `cleanup_concurrent_column_type_change` for zero-downtime column type changes
- Add `NOT NULL` constraints in post-deployment migrations (after application code is deployed); remove `NOT NULL` constraints in regular migrations
- DO NOT use `change_column` to add/remove constraints — it rewrites the entire column definition inefficiently
- Remove a non-nullable column's default value in a post-deployment migration, not in the same migration that adds the column
- Follow the `SafelyChangeColumnDefault` two-release process when changing a column default that application code may explicitly write
- When renaming or changing the type of a column referenced by a database view, recreate the view as part of the migration to point to the new column

### Dropping Tables

- Remove all application code referencing a table before dropping it
- Drop tables with no foreign keys using a post-deployment migration
- When a table has foreign keys, remove each FK in a separate post-deployment migration before dropping the table
- Add dropped tables to `db/docs/deleted_tables` per the database dictionary guide

### Renaming Tables

- Register the rename in `TABLES_TO_BE_RENAMED` in `lib/gitlab/database.rb` one release before executing `rename_table_safely`
- Use `rename_table_safely` / `undo_rename_table_safely` in a standard (non-post) migration
- Remove the view with `finalize_table_rename` in a post-deployment migration of the same release as the rename
- Remove the entry from `TABLES_TO_BE_RENAMED` in the same release as `finalize_table_rename`
- Rename the table's dictionary file under `db/docs` and create an entry for the interim view in `db/docs/deleted_views`
- DO NOT rename tables that use triggers
- DO NOT add or remove columns during the rename process; complete all table modifications before or after the rename window
- For tables with composite primary keys, explicitly set `self.primary_key` in the model before deploying the rename migration

### Column Types and Defaults

- Use `bigint` (`:integer, limit: 8`) for columns that may exceed 2 GB or for IDs on large tables
- Use `add_timestamps_with_timezone`, `timestamps_with_timezone`, or `datetime_with_timezone` instead of `add_timestamps`, `timestamps`, or `:datetime`
- Store `encrypts` attributes as `:jsonb`, not `:text`
- Add a length validation (≤ 510) for encrypted attributes stored in JSONB columns
- Use `JsonSchemaValidator` with a `size_limit` (recommended max 64 KB) for all JSONB columns
- DO NOT store unbounded JSONB data; use object storage and store references for large datasets
- Follow the multi-step process when adding/removing properties in JSONB columns validated with `additionalProperties: false`: add the property to the schema first (without marking it `required`), then add code that uses it after full deployment; for removal, remove code first, then data, then the schema entry — each step in a separate release for self-managed, or after full deployment for GitLab.com-only properties

### Data Migrations

- Prefer Arel or plain SQL over ActiveRecord syntax in data migrations
- Quote all plain SQL inputs with `quote_string`
- Migrate data in batches using `update_column_in_batches` or `each_batch_range`
- Use `Arel.sql` to wrap computed SQL values passed to `update_column_in_batches`

### Naming Conventions

- Use lowercase names for all database objects (tables, indexes, views)
- Follow [constraint naming convention guidelines](https://docs.gitlab.com/development/database/constraint_naming_convention/) for custom index and constraint names
- Keep migration timestamps within three weeks of the anticipated merge date; use `scripts/refresh-migrations-timestamps` when rebasing old branches
- DO NOT set a migration timestamp earlier than the previous required upgrade stop

### Schema Files and Checksums

- Commit `db/structure.sql` changes generated by `bundle exec rails db:migrate` — DO NOT edit it manually
- DO NOT reorder columns in `db/structure.sql` for existing tables
- Include the `db/schema_migrations/<timestamp>` checksum file in the MR that adds the migration
- Remove the checksum file when deleting a migration; regenerate it when changing a migration's timestamp
- Add new tables to the database dictionary after creation; add dropped tables to `db/docs/deleted_tables`

### High-Traffic Tables

- Use `with_lock_retries` for any DDL on [high-traffic tables](https://gitlab.com/gitlab-org/gitlab/-/blob/master/rubocop/rubocop-migrations.yml)
- Create triggers on high-traffic tables in post-deployment migrations using `with_lock_retries` with idempotent `replace: true` / `if_exists: true` guards
- DO NOT add analytics-only columns to high-traffic tables that provide no direct feature value to self-managed instances
- Include the full table name in the post-deployment migration class name so the PDM pipeline can detect and pause for autovacuum wraparound protection on that table; omit the table name only when the migration has no conflicting locks

### Batched Background Migrations

- Use the generator (`bundle exec rails g batched_background_migration`) to scaffold BBM files so all required files are created by default
- Enqueue BBMs in a post-deployment migration using `queue_batched_background_migration`; DO NOT enqueue them in regular migrations
- Define all BBM classes under the `Gitlab::BackgroundMigration` namespace in `lib/gitlab/background_migration/`
- Use cursor-based iteration (the `cursor` DSL) as the default strategy for new BBMs; omit `cursor` only when the legacy primary-key strategy is explicitly required
- Use `job_arguments` helper to declare job arguments; `queue_batched_background_migration` raises an error if the count does not match
- Set `restrict_gitlab_migration gitlab_schema:` in the scheduling post-deployment migration to match the database where the actual changes are made
- Declare `DEPENDENT_BATCHED_BACKGROUND_MIGRATIONS` in any migration that depends on a prior BBM being finished; the `Migration::UnfinishedDependencies` cop enforces this
- Ensure BBM jobs are idempotent — they run in Sidekiq and may be retried
- DO NOT silently rescue exceptions inside BBM job classes — log and re-raise so jobs are not incorrectly marked successful
- DO NOT use application models (`app/models`) in BBMs; define inline models inheriting from the correct `ApplicationRecord` subclass (`::ApplicationRecord` for `main`, `::Ci::ApplicationRecord` for `ci`); DO NOT use `ActiveRecord::Base`
- DO NOT use `ActiveRecord::Base.connection` in BBMs; use the model's connection or `ApplicationRecord.connection` instead
- When iterating over non-distinct columns, use `LooseIndexScanBatchingStrategy` and `distinct_each_batch` instead of the default primary-key strategy
- Use `scope_to` only when the scoped condition is covered by an index with an index-only scan; disable the `Database/AvoidScopeTo` cop with a comment citing the supporting index
- Use `tables_to_check_for_vacuum` when the BBM iterates over one table but writes to different tables, to avoid unnecessary autovacuum pauses on the iteration table
- Update sub-batches in a single query using a materialized CTE with a limit guard rather than updating each row individually
- For EE-only BBMs, create an empty class in GitLab FOSS and extend it in EE; define `job_arguments` in the FOSS class to prevent validation failures
- Finalize a BBM only after it has completed on GitLab.com and was enqueued at or before the last required stop; use `ensure_batched_background_migration_is_finished` in a post-deployment migration
- Match job arguments and `gitlab_schema` exactly in `ensure_batched_background_migration_is_finished` — even if the schema label changed since enqueueing
- Update `finalized_by` in the corresponding `db/docs/batched_background_migrations/<name>.yml` when adding the finalization migration
- Delete BBM code (class file, specs, YAML, enqueue/finalize migrations, schema_migrations entries) only after the next required stop following finalization
- When re-queueing a BBM, no-op the original migration's `up`/`down` and call `delete_batched_background_migration` at the start of the new migration's `up`
- When stopping and removing an in-progress BBM, no-op the scheduling migration and add a separate regular migration that calls `delete_batched_background_migration`
- Add upgrade notes for significant BBMs to help self-managed and Dedicated customers plan upgrades
- DO NOT use per-partition or view-based parallelization patterns for self-managed instances; consult the Database team before using them on GitLab.com

### Schema Migrations

- Files in `db/schema_migrations/` are auto-generated and do not require a newline at the end -- do not flag missing newlines

## BBM doc YAML required fields

When creating a `db/docs/batched_background_migrations/<name>.yml`, the YAML MUST include:

- `migration_job_name: <BBM class name in CamelCase>`
- `description: <one-line description>`
- `feature_category: <category symbol>`
- `introduced_by_url: <MR URL>` (placeholder OK for unreleased)
- `milestone: '<X.Y>'`
- `queued_migration_version: <version timestamp>`
- `gitlab_schema: <gitlab_main | gitlab_ci | gitlab_main_user | gitlab_main_org>` — match the schema of the BBM's primary table
- (optional, post-finalize) `finalized_by: <version>`

## Authoritative sources

For the full picture, see:

- doc/development/migration_style_guide.md
- doc/development/database/avoiding_downtime_in_migrations.md
- doc/development/database/post_deployment_migrations.md
- doc/development/database/batched_background_migrations.md
- doc/development/database/rename_database_tables.md


---
source_checksum: 4a7e89bf9054dabc
distilled_at_sha: 52964caf288c3d9936b8ce4a3d2242c1f92567fa
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
- Use `rename_column_concurrently` + `cleanup_concurrent_column_rename` (across two migrations) for zero-downtime column renames
- Use `change_column_type_concurrently` + `cleanup_concurrent_column_type_change` for zero-downtime column type changes
- Add `NOT NULL` constraints in post-deployment migrations (after application code is deployed); remove `NOT NULL` constraints in regular migrations
- DO NOT use `change_column` to add/remove constraints — it rewrites the entire column definition inefficiently
- Remove a non-nullable column's default value in a post-deployment migration, not in the same migration that adds the column
- Follow the `SafelyChangeColumnDefault` two-release process when changing a column default that application code may explicitly write

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
- DO NOT rename tables that use triggers

### Column Types and Defaults

- Use `bigint` (`:integer, limit: 8`) for columns that may exceed 2 GB or for IDs on large tables
- Use `add_timestamps_with_timezone`, `timestamps_with_timezone`, or `datetime_with_timezone` instead of `add_timestamps`, `timestamps`, or `:datetime`
- Store `encrypts` attributes as `:jsonb`, not `:text`
- Add a length validation (≤ 510) for encrypted attributes stored in JSONB columns
- Use `JsonSchemaValidator` with a `size_limit` (recommended max 64 KB) for all JSONB columns
- DO NOT store unbounded JSONB data; use object storage and store references for large datasets
- Follow the multi-step process (schema change → deploy → code change) when adding/removing properties in JSONB columns validated with `additionalProperties: false`

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
- doc/development/database/rename_database_tables.md


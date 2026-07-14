---
source_checksum: 86de137923c89ec6
distilled_at_sha: 9eb89263152259e883603c908db1e1cea6a1a74e
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

> **Prerequisite:** If you haven't already, also read .ai/principles/distilled/database-fundamentals.md - it contains foundational rules that apply to all database work.

# ClickHouse Principles

## Checklist

### Schema Consistency

- Check the `clickhouse:check-schema` CI job logs; if it fails, inspect differences carefully and discuss non-whitespace discrepancies with the MR author.
- DO NOT allow the `clickhouse:check-schema` job to fail without investigation — it is not allowed to fail and will block the MR pipeline.
- Add the `pipeline:skip-check-clickhouse-schema` label only for confirmed false positives (e.g., ClickHouse version mismatches).
- Ensure `db/click_house/main.sql` is updated and committed in the MR; if missing, ask the author to run `bundle exec rake gitlab:clickhouse:migrate; bundle exec rake gitlab:clickhouse:schema:dump`.

### Schema Migration Files

- Files in `db/click_house/schema_migrations/` are auto-generated and do not require a newline at the end — do not flag missing newlines

### Database Migrations

- Generate ClickHouse migrations using `bundle exec rails generate gitlab:click_house:migration MIGRATION_CLASS_NAME` rather than creating migration files manually.
- Generate post-deployment ClickHouse migrations using `bundle exec rails generate gitlab:click_house:post_deployment_migration MIGRATION_CLASS_NAME`.
- Name migration files with a `YYYYMMDDHHMMSS_description_of_migration.rb` timestamp prefix and place them in `db/click_house/migrate/`.
- Implement both `up` and `down` methods in every migration.
- Commit the schema version marker file generated under `db/click_house/schema_migrations/main/<version>` together with the migration — the `clickhouse:check-schema` CI job fails when a migration is merged without its marker file; if you lack a local ClickHouse instance, run the migration to generate the marker file before committing.

### Dictionaries

- Use `create_dictionary` (not raw `CREATE DICTIONARY`) when defining ClickHouse dictionaries in migrations — it injects credentials and prepends the database name to tables automatically.
- Specify all participating tables in the `source_tables` argument of `create_dictionary` so the database name is correctly prepended in the `QUERY`.
- Use only the `CLICKHOUSE` source referencing the `main` database for dictionaries; DO NOT reference external dictionary sources.
- Account for potential data staleness when using dictionaries — always consider consistency requirements and ways to correct inconsistent data eventually.

### Database Query Review

- Use ClickHouse placeholder syntax for variable interpolation to prevent sensitive data from being logged: `sql = 'SELECT * FROM events WHERE id > {min_id:UInt64}'`.
- Use proper quoting via `ClickHouse::Client::Quoting.quote(...)` for fixed string interpolation assigned to Ruby constants to prevent SQL injection.
- DO NOT use raw string interpolation for user-controlled or dynamic values in ClickHouse queries.
- Use `ClickHouse::Client::Query` with named placeholders and a `placeholders` hash for parameterised queries; use the `Subquery` type to compose nested queries safely.
- Use `ClickHouse::Client::QueryBuilder` for queries with multiple filter conditions instead of concatenating query fragments as strings.

### Data Insertion

- Insert data in batches rather than single-row `INSERT` statements; DO NOT build large `INSERT` queries in memory.
- Use `CsvBuilder::Gzip` with `ClickHouse::Client.insert_csv` to compress data and reduce memory usage during batch inserts.
- Use single-row `INSERT` via `ClickHouse::Client.execute` only for settings/configuration rows or test data setup.

### Iterating Over Tables

- Use `ClickHouse::Iterator` for batching over large volumes of ClickHouse data; ensure the iteration column is a single integer with no huge gaps.
- Use the `:order_limit` min-max strategy (`min_max_strategy: :order_limit`) for partitioned tables where `MIN`/`MAX` aggregations cause full table scans.
- Ensure iteration queries do not scan the whole table — add appropriate filters and verify the schema supports efficient filtered iteration.

### Query Performance Review

- Ask the author to provide raw SQL if it is not clearly visible in the code.
- Review the table structure (`SHOW CREATE TABLE table_name FORMAT raw`) to understand partitioning and primary keys.
- Confirm that query filters align with the table's primary key or partitioning columns.
- Use `EXPLAIN indexes=1` to verify that filters use primary key indexes; check the Granules ratio in the `PrimaryKey` section.
- Raise a performance discussion when the query scans more than 10 million rows, consistently exceeds 5-10 seconds, or will be frequently executed.
- Ensure performance validation uses real-world or synthetic data from large namespaces (e.g., `gitlab-org` or `gitlab-org/gitlab`).
- Ensure query execution targets under 10 seconds even for complex aggregations.

### Materialized Views

- Ensure new materialized views are created with the `POPULATE` keyword or have a backfill migration for large datasets.

### Table Engine Usage

- Use `MergeTree` only when data is strictly append-only and duplicates cannot occur.
- Ensure `ReplacingMergeTree` tables provide a monotonic version column (typically `DateTime64`) and an optional deleted flag (`Bool`) for soft deletes.
- DO NOT omit the version parameter in `ReplacingMergeTree` — without it, the deduplicated row after a merge is arbitrary.
- Use `argMax` by the version column with `GROUP BY` on the primary key for query-time deduplication in production queries.
- DO NOT use `FINAL` in production queries — it forces on-the-fly collapsing/merging and can be very expensive I/O-wise; prefer the query-time dedup pattern instead.

### Column Compression

- Apply `CODEC(DoubleDelta, ZSTD)` to integer and timestamp primary key / sorted columns; apply `CODEC(ZSTD(3))` to high-entropy string primary key columns.
- Apply `CODEC(Delta, ZSTD(1))` to incremental timestamp columns (`created_at`, `updated_at`); apply `CODEC(ZSTD(1))` to boolean, UUID, and hash columns; apply `CODEC(ZSTD(3))` to longer text or JSON columns.
- DO NOT over-optimize compression — DO NOT use ZSTD levels above 3 unless storage gains are significant, as higher levels increase CPU overhead during reads and writes.
- Measure compression efficiency using the `system.columns` query comparing `data_compressed_bytes` to `data_uncompressed_bytes` before choosing a non-default codec.

### Sidekiq Workers

- Include the `ClickHouseWorker` module in every Sidekiq worker that interacts with ClickHouse to pause the worker during migrations and prevent migrations from running while the worker is active.
- Add `tags :clickhouse` metadata to all Sidekiq workers that interact with ClickHouse to enable routing to a dedicated Sidekiq shard.

### GraphQL Pagination

- Return a `ClickHouse::Client::QueryBuilder` object from GraphQL resolvers that paginate ClickHouse queries.
- Ensure `ORDER BY` columns are `NOT NULL` and uniquely identify each row for keyset pagination compatibility.
- Use a nested `SELECT` with `GROUP BY` and `argMax` for deduplication when querying `ReplacingMergeTree` tables from a GraphQL resolver.

### Siphon Schema Synchronisation

- When adding a new column to a PostgreSQL table that is synchronised to ClickHouse via Siphon, generate a corresponding ClickHouse migration to add the matching column to the `siphon_`-prefixed table.
- Check `Gitlab::ClickHouse::SiphonGenerator::PG_TYPE_MAP` for the correct ClickHouse type mapping when adding Siphon columns; using the wrong type triggers a CI error.
- Prefer `LowCardinality` where appropriate and use `Nullable` sparingly — prefer default values over `Nullable` columns in Siphon tables.

### Testing

- Tag RSpec tests that require a running ClickHouse server with `:click_house` to ensure the database schema is set up before the test case.

### Verify Before Flagging

When a diff modifies or replaces an existing structure, always verify the current state from an
authoritative source before flagging a discrepancy. Never infer the pre-change state solely from
diff context — check the actual source of truth. For example:

- **Migration `down` methods**: verify the `down` schema against the actual pre-migration schema by
  querying the local ClickHouse database (`SHOW CREATE TABLE tablename`) or, if unavailable, reading
  the schema from the base branch (`git show master:db/click_house/main.sql`). Compare
  column-by-column: names, types, defaults, engine, primary key, ORDER BY, and SETTINGS.
- **Table recreation** (`DROP TABLE IF EXISTS` + `CREATE TABLE`): verify the old table definition
  the same way before claiming columns or settings are missing.

## Authoritative sources

For the full picture, see:

- doc/development/database/clickhouse/reviewer_guidelines.md
- doc/development/database/clickhouse/clickhouse_within_gitlab.md


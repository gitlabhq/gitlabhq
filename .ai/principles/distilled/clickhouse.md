---
source_checksum: 3716411bdf5dbc60
distilled_at_sha: 52964caf288c3d9936b8ce4a3d2242c1f92567fa
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

### Database Query Review

- Use ClickHouse placeholder syntax for variable interpolation to prevent sensitive data from being logged: `sql = 'SELECT * FROM events WHERE id > {min_id:UInt64}'`.
- Use proper quoting via `ClickHouse::Client::Quoting.quote(...)` for fixed string interpolation assigned to Ruby constants to prevent SQL injection.
- DO NOT use raw string interpolation for user-controlled or dynamic values in ClickHouse queries.

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


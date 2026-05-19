---
source_checksum: 1d9f35bb1b585b6b
distilled_at_sha: 52964caf288c3d9936b8ce4a3d2242c1f92567fa
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

> **Prerequisite:** If you haven't already, also read .ai/principles/distilled/database-fundamentals.md - it contains foundational rules that apply to all database work.

# Database Principles

## Checklist

### Query Performance

- Ensure general queries execute under 100ms (both cold and warm cache)
- Ensure migration queries execute under 100ms (excluding total migration time)
- Ensure concurrent migration operations (`add_concurrent_index`, `add_concurrent_foreign_key`, validate constraint) complete within 5min for migrations and 20min for post-migrations
- Ensure background migration queries execute under 1s
- Ensure Service Ping queries execute under 1s
- Analyze query plans using `EXPLAIN(analyze, buffers)` and document results in the MR description for sequential scans on large tables, nested loops with large datasets, missing or inefficient index usage, high-cost operations, unexpected sort operations
- Verify query plans reflect the complete query as executed (including all chained scopes, pagination, ordering)
- Verify queries return expected records (not zero rows)
- Check maximum query execution time is under 100ms in query plan analysis
- Consider async index creation if index creation in post-migrations exceeds 20 minutes

### SQL Query Guidelines

- Use Arel `matches` instead of raw `LIKE`/`ILIKE` SQL fragments to ensure correct case-insensitive behavior on PostgreSQL
- DO NOT use `LIKE`/`ILIKE` with a leading wildcard (for example, `ILIKE '%value'`) without a trigram GIN index
- Name trigram GIN indexes using the pattern `index_TABLE_on_COLUMN_trigram`
- Create trigram GIN indexes concurrently using `disable_ddl_transaction!` in migrations
- Explicitly qualify column names with table names in `SELECT` statements when using `JOIN`s to avoid ambiguous column errors during deployment
- DO NOT use `pluck` to load IDs into memory for use as arguments in another query; use subqueries instead. Exception: when using CTEs with `update_all`, first pluck IDs from the CTE result and scope the update to those IDs (the CTE is dropped otherwise)
- Use `pluck` only within model code, or when values are needed in Ruby or cached for multiple related queries
- Limit `pluck` results to `MAX_PLUCK` (1,000) records when `pluck` is necessary
- Use `WHERE EXISTS` instead of `WHERE IN` wherever possible
- Check all query variants (`.exists?`, `.count`, pagination) for query plan flip issues when using complex scopes with `IN` subqueries
- Use a CTE (via `Gitlab::SQL::CTE`) to stabilize query plans when `.exists?` causes plan flips, but only as a last resort
- DO NOT use CTEs with `UPDATE` or `DELETE` — the CTE is dropped and the operation affects the entire table. Exception: when using CTEs with `update_all`, first pluck IDs from the CTE result and scope the update to those IDs
- DO NOT update large volumes of unbounded data without batching; use `iterating_tables_in_batches` patterns
- Prefer `ORDER BY id` over `ORDER BY created_at` unless accurate creation-date ordering is required
- Use `ORDER BY created_at, id` (with appropriate composite index) when accurate creation-date ordering is required, especially in Cells architecture
- Use `UNION` (via `Gitlab::SQL::Union` or `FromUnion`) instead of complex `JOIN`s when combining result sets from multiple queries
- DO NOT mix `SELECT column_names` with `SELECT *` in `UNION` sub-queries; use consistent column selection across all sub-queries
- Use `User.cached_column_list` for explicit column lists in `UNION` queries to avoid stale schema cache issues
- Inherit models from `ApplicationRecord` or `Ci::ApplicationRecord`, not `ActiveRecord::Base`; use `MigrationRecord` only in migration context
- DO NOT use `.find_or_create_by` or `.first_or_create` — they are not atomic; use `ApplicationRecord.safe_find_or_create_by` or `.upsert` instead
- Use `.safe_find_or_create_by` only in isolated code not wrapped in an existing transaction (subtransactions carry risk)
- Prefer `.upsert` with `unique_by` when the common path is record creation and duplicate avoidance is only needed on edge cases

### Transaction Guidelines

- Use `Model.transaction` when all records in the block belong to the same database table/connection; use `ApplicationRecord.transaction` (not `ActiveRecord::Base.transaction`) only when the model is not known or records span multiple models
- DO NOT use `ApplicationRecord.transaction` for models on a different database (for example, `Ci::*` models on `CiDatabase`) — statements will not be rolled back
- Keep transaction blocks as short as possible to minimize lock contention
- DO NOT perform external network requests (Sidekiq jobs, emails, HTTP calls, different-connection DB statements), file system operations, long CPU-intensive computation, or `sleep(n)` inside a transaction block

### Large Tables

- DO NOT add an index to a table exceeding 50 GB without a Database team exception
- DO NOT add a column with a foreign key to a table exceeding 50 GB without a Database team exception
- DO NOT add a new column to a table exceeding 100 GB without a Database team exception
- Request a schema change exception via the Database Team Tasks template and link the approval issue when disabling the cop
- Consider archiving, data retention policies, table partitioning, column optimization, normalization, or external storage before requesting an exception
- Use a `has_one` relationship to a new table instead of adding columns to an oversized main table when the new data applies to only a subset of rows

### Batching

- Use `each_batch` (via `EachBatch` module) instead of Rails `in_batches` for iterating large tables
- DO NOT use `each_batch` on non-unique columns without calling `distinct` first — it may cause infinite loops
- Use `distinct_each_batch` for iterating over non-unique columns using the loose-index scan technique
- Use smaller batch sizes with `distinct_each_batch` than with standard `each_batch` due to recursive CTE overhead
- Perform batching in background jobs (Sidekiq workers), not in web requests
- Limit background job runtime (use `Gitlab::Metrics::RuntimeLimiter`) and implement a "continue later" mechanism by scheduling a new job with a cursor when the limit is reached
- Add a rest period (`sleep 0.01`) between batches when large volumes of data are modified to reduce primary database pressure
- Expose batching metrics via `log_extra_metadata_on_done` for traceability in Kibana
- Use keyset pagination (`Gitlab::Pagination::Keyset::Iterator`) when iterating by timestamp columns or composite primary keys where `EachBatch` cannot be used
- DO NOT use offset pagination for new features — use it only as a short-term stop-gap
- Use `each_batch_count` instead of summing `relation.count` inside `each_batch` for counting large tables
- DO NOT add subqueries to the outer `each_batch` scope — move filters to the yielded `relation` inside the block
- Use a CTE trick (`Gitlab::SQL::CTE`) on the yielded relation when complex conditions cause unstable query plans inside `each_batch`
- Use loop-based batching only for short-lived delete/update operations affecting at most ~10k rows
- Use `BulkInsertSafe` / `bulk_insert!` for inserting large arrays of ActiveRecord objects in bulk
- Use `BulkInsertableAssociations` with `with_bulk_insert` to bulk-insert `has_many` associations
- Limit bulk insert input to ~1,000 records per call to avoid large single transactions
- Use the background operations framework (BBO) for recurring data operations such as purging stale rows or deleting expired records, instead of building custom batching logic

### Pagination Performance

- Include a tie-breaker unique column (for example, `id`) in all `ORDER BY` clauses to ensure stable sort order
- Ensure composite indexes match the exact column order of the `ORDER BY` clause
- DO NOT mix `ORDER BY` columns from different tables — denormalize if necessary to keep sort columns in one table
- Be aware that group-level queries (group + subgroups) are inherently expensive; avoid adding further joins or subqueries without profiling
- Consider denormalization (adding `project_id` or sort columns to join tables) only when query performance cannot be achieved otherwise, and document the trade-offs

### ActiveRecord Scopes

- New or modified scopes should have appropriate indexes for filtered columns
- Scopes should avoid expensive operations like subqueries on large tables
- Default scopes are avoided unless absolutely necessary (they can cause unexpected query behavior)

### Partitioned Tables

- Leverage partition pruning wherever possible when querying partitioned tables to minimize LWLock contention

### Query Plan Analysis

- Analyze query plans in the MR description for:
  - Sequential scans on large tables
  - Nested loops with large datasets
  - Missing or inefficient index usage
  - High-cost operations
  - Unexpected sort operations
  - Verify the query returns expected records (not zero rows)
  - Check that maximum query execution time is under 100ms
  - Ensure the query plan reflects the complete query as executed (including all chained scopes, pagination, ordering)

## Authoritative sources

For the full picture, see:

- doc/development/database/query_performance.md
- doc/development/database/transaction_guidelines.md
- doc/development/database/large_tables_limitations.md
- doc/development/sql.md
- doc/development/database/batching_best_practices.md
- doc/development/database/iterating_tables_in_batches.md
- doc/development/database/insert_into_tables_in_batches.md
- doc/development/database/pagination_performance_guidelines.md


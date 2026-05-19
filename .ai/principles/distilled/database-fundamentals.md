---
source_checksum: e786b4cacd62e727
distilled_at_sha: 9ab16c7588f7d32fdb6d509a70bae72309346826
---
<!-- Auto-generated from docs.gitlab.com by scripts/ai/sync_principles.rb — do not edit manually -->

# Database Principles

## Checklist

### Process Reminders

- Ask: "Have you triggered the `db:gitlabcom-database-testing` pipeline?"
- For new or modified queries: raw SQL and query plans should be documented in the MR description
- For creating or dropping tables/views: ensure the Database Dictionary is updated
- Flag all modified or new ActiveRecord scopes as needing a database reviewer

### Process and Artifacts

- Ensure `db/structure.sql` is updated and relevant version files under `db/schema_migrations` were added or removed.
- Verify the `db:check-migrations` and `db:check-schema` pipeline jobs ran successfully.
- Require query plans for each raw SQL query, linked directly after each SQL snippet in the MR description.
- For updated queries, require both old and new raw SQL with their respective query plans.
- Ensure query plans hit enough data (use `gitlab-org` namespace ID `9970`, project IDs `13083`/`278964`, or user ID `1614863`); DO NOT accept plans returning 0 records unless the query is an `UPDATE`.
- For data migrations that delete records, require the `~data-deletion` label and a description of how deleted data could be recovered.
- For new tables, require answers in the MR description about anticipated growth (3/6/12 months) and read/write access patterns.

### Migration Standards

- Check migrations are reversible via `change` method or explicit `down` method; data migrations must include a rollback procedure or explanation of why it is non-reversible.
- Ensure migrations run within a transaction (Rails default) or use only concurrent operations with `disable_ddl_transaction!`.
- Check [timing guidelines](https://docs.gitlab.com/development/migration_style_guide/#how-long-a-migration-should-take): cumulative query time in a single transactional migration must fit comfortably within 15 seconds on GitLab.com.
- Ensure general query execution time stays below 100ms.
- Choose the appropriate [migration type](https://docs.gitlab.com/development/migration_style_guide/#choose-an-appropriate-migration-type) (regular, post-deploy, background).
- DO NOT disable RuboCop checks in migrations unless there is a documented valid reason.
- Verify lock retries are enabled for transactional migrations (enabled by default); for non-transactional migrations, review the relevant documentation.

### Large Tables and Indexes

- Verify indexes and columns are not added to pre-existing tables over the [size threshold](https://docs.gitlab.com/development/database/large_tables_limitations/).
- When adding an index to a large table, require execution via `CREATE INDEX CONCURRENTLY` tested in Database Lab with execution time noted in the MR description.
- If Database Lab execution time exceeds 10 minutes, require the index to be moved to a post-deployment migration and added [asynchronously](https://docs.gitlab.com/development/database/adding_database_indexes/#create-indexes-asynchronously).
- After merging an MR with an elevated-execution-time index, notify Release Managers on `#f_upcoming_release`.

### Table and Column Design

- Order columns per the [Ordering Table Columns](https://docs.gitlab.com/development/database/ordering_table_columns/) guidelines.
- Ensure foreign keys exist for all columns referencing other tables, with accompanying indexes.
- Add indexes for columns used in `WHERE`, `ORDER BY`, `GROUP BY`, and `JOIN` clauses.
- Require new tables to be seeded by a file in `db/fixtures/development/`.
- DO NOT use database tables to store [static data](https://docs.gitlab.com/development/cells/#static-data); use a [fixed items model](https://docs.gitlab.com/development/fixed_items_model/) instead.
- For column removals, verify the column was [ignored in a previous release](https://docs.gitlab.com/development/database/avoiding_downtime_in_migrations/#dropping-columns) before being dropped.
- When adding a composite index, remove any indexes that become redundant (e.g., adding `index(A, B, C)` makes `index(A, B)` and `index(A)` redundant).
- When dropping indexes, verify composite indexes can serve as replacements by checking column order requirements.
- Remove indexes and foreign keys in a post-deployment migration (except for small tables).
- Include a migration to remove orphaned rows **before** adding a foreign key to an existing table.
- Remove any `dependent: ...` associations that become unnecessary after adding a foreign key migration.

### Background Migrations

- Verify background migrations are used for large table data migrations or operations requiring many SQL queries per record.
- Review batch sizes for background migration queries.
- Check time estimates from the `gitlab-com-database-testing` comment against [query performance guidelines](https://docs.gitlab.com/development/database/query_performance/#timing-guidelines-for-queries).

### Query Performance

- Check for N+1 query problems and minimize query count.
- Verify all new and modified queries include SQL statements and query plans from Database Lab in the MR description.
- Review query plans using [understanding EXPLAIN plans](https://docs.gitlab.com/development/database/understanding_explain_plans/) guidance and suggest improvements (restructuring, index changes).
- For bulk operations (`update`, `upsert`, `delete`, `update_all`, `upsert_all`, `delete_all`, `destroy_all`), require raw SQL and query plan in the MR description and a database review.
- DO NOT use bulk update operations inside Common Table Expression (CTE) statements (they are incompatible).

### Multiple Databases (Cross-Database Safety)

- DO NOT write queries that JOIN across `main`, `ci`, `sec`, or `geo` database schemas.
- Use `preload` instead of `includes` when `includes` would generate a cross-database join.
- Use `disable_joins: true` on `has_one`/`has_many through:` associations that span databases, and verify intermediate result sets are bounded (have `LIMIT 1` or a unique-column `WHERE` clause).
- DO NOT use `pluck` to map unbounded cross-database ID sets; use bounded alternatives.
- Wrap unavoidable existing cross-joins with `::Gitlab::Database.allow_cross_joins_across_databases(url: ...)` pointing to a tracking issue; DO NOT override ActiveRecord associations to allow cross-joins.
- DO NOT open transactions that modify tables across multiple databases (cross-database transactions); use asynchronous jobs or remove the transaction block instead.
- DO NOT use `dependent: :nullify` or `dependent: :destroy` across databases; use `dependent: :restrict_with_error` or [loose foreign keys](https://docs.gitlab.com/development/database/loose_foreign_keys/) instead.
- Ensure each model uses the correct base class for its `gitlab_schema` (`ApplicationRecord` for `gitlab_main_org`, `Ci::ApplicationRecord` for `gitlab_ci`, `Geo::TrackingBase` for `gitlab_geo`, etc.).
- For cross-database foreign keys, add an allowlist entry in `no_cross_db_foreign_keys_spec.rb` and plan conversion to a loose foreign key.
- Use `skip_if_shared_database`, `skip_if_database_exists`, `skip_if_multiple_databases_are_setup`, or `skip_if_multiple_databases_not_setup` helpers in specs that must run only in specific database modes.

### Verify Before Flagging

- When a diff modifies or replaces an existing structure, always verify the current state from an authoritative source before flagging a discrepancy. Never infer the pre-change state solely from diff context — check the actual source of truth. For example:

  - **Migration `down` methods**: verify the `down` schema against the actual pre-migration schema by querying the local PostgreSQL database (`\d tablename`) or, if unavailable, reading the schema from the base branch (`git show master:db/structure.sql`).
  - **Table or column modifications**: verify what currently exists before claiming something was lost or changed incorrectly.

## Authoritative sources

For the full picture, see:

- doc/development/database_review.md
- doc/development/database/multiple_databases.md


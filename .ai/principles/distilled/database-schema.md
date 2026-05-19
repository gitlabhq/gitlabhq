---
source_checksum: 6fe8057bc1c8d386
distilled_at_sha: 52964caf288c3d9936b8ce4a3d2242c1f92567fa
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

> **Prerequisite:** If you haven't already, also read .ai/principles/distilled/database-fundamentals.md - it contains foundational rules that apply to all database work.

# Database Principles

## Checklist

### Indexes

- DO NOT add an index without first checking if existing indexes can be reused or modified
- DO NOT add an index to a table that already has 15 indexes without first removing or combining existing ones
- DO NOT use hash indexes; use B-tree indexes instead (RuboCop enforces this)
- DO NOT create indexes concurrently on partitioned tables directly; use `add_concurrent_partitioned_index` instead
- DO NOT add a new index without making the corresponding application code change in the same MR when possible
- Use a post-deployment migration for indexes that improve existing queries (they are non-critical to operations)
- Use `add_concurrent_index` for indexes on populated tables (never inside a transactional migration)
- Use partial indexes (`WHERE` clause) when queries always filter on a known condition and target a subset of data
- Prefix temporary index names with `tmp_` and create a follow-up issue to remove them in the next milestone
- Add a comment in the migration referencing the removal issue for temporary indexes
- For expression indexes used before a batched background migration, run `ANALYZE` explicitly in the post-deployment migration (only for non-large tables)
- Use `prepare_async_index` / `prepare_partitioned_async_index` for very large tables to schedule index creation during low-traffic windows
- Provide an explicit `name:` argument for any index created with `where`, `using`, `order`, `length`, `type`, or `opclass` options
- Follow the constraint naming convention for indexes: `index_<table>_on_<column>[_and_<column>]*`; keep names all lowercase
- Use `index_name_exists?` (or `index_exists?` with `name:`) to test for index existence by name
- For unique indexes on existing tables, use multiple post-deployment migrations across multiple releases to remove duplicates before adding the constraint
- Ensure all unique indexes are scoped per Cells requirements
- Use `nulls_not_distinct: true` on unique indexes when you need to enforce full uniqueness including `NULL` values, instead of combining two separate indexes
- When dropping a composite index, verify that queries filtering only on non-leading columns have another suitable index
- For large tables, use `prepare_async_index_removal` to schedule index removal asynchronously, then add a synchronous follow-up migration after verifying removal in production

### Index Removal

- Before removing an index, verify queries can use other existing indexes efficiently
- Confirm the index is unused on GitLab.com and Self-Managed
- For investigating index usage, check Grafana dashboards for index usage data

### Foreign Keys

- Add a foreign key whenever adding an association to a model or creating a table that references another table
- Add a concurrent index on the foreign key column before adding the foreign key constraint
- Define every foreign key as `bigint`, even if the referenced table has an `integer` primary key
- Define an `ON DELETE` clause on every foreign key (use `CASCADE` in 99% of cases)
- Use `add_concurrent_foreign_key` with `validate: false` when adding a FK to an existing column, then validate in a separate migration
- DO NOT validate a foreign key while a batched background migration cleaning up related data is still running
- DO NOT use `add_foreign_key` or `add_concurrent_foreign_key` more than once per migration file unless source and target tables are identical
- Use `reverse_lock_order: true` for high-traffic tables when adding or removing foreign keys to avoid deadlocks
- Use `remove_partitioned_foreign_key` instead of `remove_foreign_key` when removing FKs from partitioned tables
- For composite indexes serving as FK indexes, ensure the FK column is in the leading position
- DO NOT use `dependent: :destroy` or `dependent: :delete` on associations; let the database handle cascading deletes via FK constraints
- DO NOT define `before_destroy` or `after_destroy` callbacks unless approved by database specialists; use service classes for non-database cleanup
- Use `_id` suffix only for columns referencing another table; use `_xid` for third-party platform IDs
- Add columns with `_id` suffix to `ignored_fk_columns_map` in `spec/db/schema_spec.rb` only when they meet the documented criteria (cross-schema, loose FK, polymorphic, or non-reference)
- For FK validation on very large tables, use `prepare_async_foreign_key_validation` / `prepare_partitioned_async_foreign_key_validation` to schedule validation during low-traffic windows
- When adding two foreign keys to a new table, split them into different migrations to avoid locking more than one table at a time

### NOT NULL Constraints

- Add `NOT NULL` constraints to all columns that should never be `NULL`
- For new tables, define `NOT NULL` directly in `create_table`
- For existing columns, use a multi-release process: add `NOT VALID` constraint → fix existing records → validate in next release
- Use `add_not_null_constraint` helper (not raw `ALTER TABLE`) for adding constraints to existing columns
- For `belongs_to` associations requiring presence, use `optional: false` instead of a separate `validates :field, presence: true`; note that `config.active_record.belongs_to_required_by_default = false` is set in GitLab, so mark required associations explicitly
- DO NOT combine DDL (schema changes) and DML (data modifications) in a single migration
- For large tables, use a batched background migration to fix records, finalize it, then add the `NOT NULL` constraint in a subsequent release
- For very large tables, add the constraint with `validate: false` first, then use `prepare_async_check_constraint_validation` for asynchronous validation
- DO NOT drop a `NOT NULL` constraint from an individual partition; drop it from the parent table so it cascades
- Use `add_multi_column_not_null_constraint` when enforcing that a specific number of columns across a set must be non-null (e.g., exactly one of `project_id` or `group_id` must be present)

### Text Columns and Limits

- Use `text` data type instead of `string` for all string/text columns
- Always set a limit on `text` columns: use `limit:` in `create_table` or `add_text_limit` on existing tables
- For new tables, add text limits in the same migration as table creation
- For existing columns, add the limit as `NOT VALID` in a post-deployment migration, fix existing records, then validate in the next release
- To increase a text limit, add the new constraint with a different name before removing the old one
- DO NOT use `text` columns for `encrypts` attributes; use `:jsonb` columns instead
- Add a rubocop disable comment when adding a text column without a limit (with a reference to the follow-up migration)

### Enums

- Use `SMALLINT` (`limit: 2`) for all new enum columns
- Define all enum key/value pairs in FOSS, even for EE-only values
- DO NOT define EE-only enum values in a separate module with an offset workaround
- Fill gaps in enum integer sequences before appending new values at the end
- Consider using a fixed items model instead of a database-backed enum when data is static, never changes at runtime, and must have consistent IDs across Cells

### Column Ordering

- Order columns in new tables by type size descending (largest fixed-size types first, variable-size types last) to minimize alignment padding

### Polymorphic Associations

- DO NOT use polymorphic associations (Rails `source_type`/`source_id` pattern); use separate tables for each type instead
- DO NOT add `*_type` columns as a pattern for future polymorphic expansion

### Serialized Data

- DO NOT store serialized data (JSON, YAML, comma-separated values) in database columns; use separate columns or tables instead

### Single Table Inheritance

- DO NOT design new tables using Single Table Inheritance (STI)
- DO NOT add new types to existing STI tables; consider splitting into separate tables
- Disable STI (`self.inheritance_column = :_type_disabled`) when using models in migrations
- Use `define_batchable_model` helper in migrations instead of defining a model class when only STI disabling or `EachBatch` is needed
- If STI is unavoidable, use an enum type with the `EnumInheritance` concern instead of storing the class name string

### Check Constraints

- Use `CHECK` constraints to enforce data integrity rules beyond `NOT NULL`
- When adding a `CHECK` constraint with a default value that satisfies the constraint, add with `validate: false` in the regular migration and validate in a post-deployment migration
- Follow the naming convention: `check_<table>_<column>[_<suffix>]`

### Constraint Naming

- Follow the naming conventions: `pk_<table>`, `fk_<table>_<col>_<foreign_table>`, `index_<table>_on_<col>`, `unique_<table>_<col>`, `check_<table>_<col>[_<suffix>]`, `excl_<table>_<col>[_<suffix>]`
- Keep constraint names under PostgreSQL's 63-character limit; abbreviate or omit `_and_` joiners if needed
- Check `db/structure.sql` for naming conflicts before adding new constraints
- Use prefixes over suffixes for constraint names to enable quick type identification and alphabetical grouping

## Authoritative sources

For the full picture, see:

- doc/development/database/adding_database_indexes.md
- doc/development/database/foreign_keys.md
- doc/development/database/not_null_constraints.md
- doc/development/database/ordering_table_columns.md
- doc/development/database/strings_and_the_text_data_type.md
- doc/development/database/creating_enums.md
- doc/development/database/constraint_naming_convention.md
- doc/development/database/check_constraints.md
- doc/development/database/polymorphic_associations.md
- doc/development/database/serializing_data.md
- doc/development/database/single_table_inheritance.md
- doc/development/database/hash_indexes.md


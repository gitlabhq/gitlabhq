---
source_checksum: 65cea972b6221fba
distilled_at_sha: 446a9cf853f53fba2ba736df164bec025a2b6caf
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Testing Migrations Principles

## Checklist

### When to Write a Migration Test

- Write migration tests for all post migrations (`db/post_migrate`) and background migrations (`lib/gitlab/background_migration`) — these are mandatory.
- Write a migration test for all data migrations — these are mandatory.
- Write migration tests for other migrations only when necessary; schema-only post migrations are exempt.

### File Placement and Tagging

- Place migration specs in `(ee/)spec/migrations/` or `spec/lib/(ee/)background_migrations/` — the `:migration` RSpec tag is applied automatically.
- When testing a migration against a database schema other than `:gitlab_main` (for example `:gitlab_ci`), explicitly specify it with an RSpec tag like `migration: :gitlab_ci`.

### Loading Migration Files

- Use `require_migration!` at the top of every migration spec to load the migration file (migration files are not autoloaded by Rails).
- When a spec requires multiple migration files, pass the filename explicitly to additional calls: `require_migration!('populate_bar_column')`.

### Test Data

- Use the `table` helper to create test data in migration specs (e.g., `table(:projects).create!(...)`); DO NOT use FactoryBot in migration specs, as it relies on application code that may change after the migration runs.

### Running the Migration Under Test

- Use the `migrate!` helper to run the migration under test; DO NOT call the migration's `up` method directly, as `migrate!` also bumps the schema version in `schema_migrations` (required for the `after` hook to work correctly).
- Use the `reversible_migration` helper to test migrations that implement `change` or both `up` and `down` hooks; it verifies that state after reversal matches state before the migration ran.

### Custom Matchers for Background Migrations

- Use the `have_scheduled_batched_migration` matcher to verify that a `BatchedMigration` record was created with the expected class, table, column, job arguments, and attributes (e.g., `interval`).
- Use the `be_finalize_background_migration_of` matcher to verify that a migration calls `finalize_background_migration` with the expected background migration class.

### Transaction Behavior

- DO NOT depend on a database transaction being present in migration specs — these tests use a deletion cleanup strategy and do not run within a transaction.
- Add `:migration_with_transaction` metadata only when testing migrations that alter seeded data in `deletion_except_tables`, so the test runs within a transaction and data is rolled back to original values.

## Authoritative sources

For the full picture, see:

- doc/development/testing_guide/testing_migrations_guide.md


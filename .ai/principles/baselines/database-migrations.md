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

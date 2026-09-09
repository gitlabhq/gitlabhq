---
source_checksum: e72383a0b25128dc
distilled_at_sha: 586530a94f045df52e8ae3e37a72e449e7dd1e43
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Cells Fundamentals Principles

## Checklist

### Compute Scope

- Design for Cells as a GitLab.com-only deployment; GitLab Self-Managed and GitLab Dedicated run as a single cell.
- Scope all Web/API requests and Sidekiq workers to a single organization; allow cross-organization Sidekiq work only for recurring, idempotent cron jobs.
- DO NOT introduce cross-cell access to organization data — all data and compute for an organization must live on a single cell.

### Request Routing

- Ensure every cell-local service that accepts external requests is routable to the correct cell based on the organization the request is for.
- Apply the routable requirement to all request types and protocols, including Web, API, Git, and service-specific protocols (for example, KAS or the container registry).

### Organization Data Ownership

- Ensure organization data is migratable to another cell for all stateful cell-local services.
- Ensure every customer-data table in the GitLab Rails monolith has a traceable path to an organization through its sharding key.
- Define a sharding key on every new model that stores customer data so each row is attributable to a single organization.
- Require every newly created table in an organization-level schema (`gitlab_main_org`, `gitlab_ci`, `gitlab_sec`, `gitlab_main_user`, `gitlab_shared_org`) to define a `sharding_key` in its corresponding `db/docs/` file.
- DO NOT add a sharding key to cell-local tables — their data is never migrated between cells.
- Mark non-customer data (data that does not belong to a customer organization) as cell-local in the schema classification.
- Confirm that the ownership of each row is unambiguous when designing a new table or extending an existing one — ambiguous ownership blocks future cell migrations.

### Customer-Owned Resources

- DO NOT introduce new customer-owned resources that exist outside of an organization — all customer data must belong inside an organization.

### Cross-Organization Isolation

- DO NOT assume all organizations on the same cell are isolated from each other; controls that provide cross-organization isolation must account for whether an organization has opted into isolation.

### Schema Classification

- Use `gitlab_main_org` for all tables in the `main:` database that belong to an organization (for example, `projects` and `groups`).
- Use `gitlab_main_cell_setting` for cell-setting tables in the `main:` database (for example, `application_settings`); ensure these tables are not referenced by foreign keys from organization tables.
- Use `gitlab_main_cell_local` for tables in the `main:` database that are distinct per cell (for example, `zoekt_nodes`, `shards`); ensure these tables are not referenced by foreign keys from organization tables.
- Use `gitlab_ci` for all tables in the `ci:` database that belong to an organization (for example, `ci_pipelines`, `ci_builds`).
- Use `gitlab_ci_cell_local` for tables in the `ci:` database that are distinct per cell (for example, `instance_type_ci_runners`, `ci_cost_settings`); ensure these tables are not referenced by foreign keys from organization tables.
- Use `gitlab_main_user` only for user functionality that is not organizational level; prefer `gitlab_main_org` for most user functionality (for example, commenting on an issue).
- Use `gitlab_shared_org` for tables with data across multiple databases that have `organization_id` for sharding; DO NOT use auto-incrementing integer primary keys — use composite or UUID primary keys instead.
- Use `gitlab_shared_cell_local` for cell-local shared tables that do not require sharding and exist across multiple databases (for example, `loose_foreign_keys_deleted_records`).
- Inherit models for `gitlab_shared_org` and `gitlab_shared_cell_local` tables from `Gitlab::Database::SharedModel`.
- Use `gitlab_sec_cell_local` for tables in the `sec:` database that hold cell-local, non-customer reference data with no sharding key (for example, malware and package-metadata advisories); these rows are the same for every organization in a cell and are replicated per cell — use `SecApplicationRecord` for models on this schema.
- DO NOT use the deprecated `gitlab_main` schema — use `gitlab_main_org` instead.
- Fix pipeline failures caused by cross-database joins, cross-database transactions, or cross-database foreign keys after assigning a schema (see `doc/development/multiple_databases.md` for remediation guidance).

### Creating New Schemas

- Default new schemas to `require_sharding_key: true` so that all tables assigned to the schema must define a sharding key.
- Configure the list of allowed `sharding_root_tables` (for example, `projects`, `namespaces`, `organizations`) in the schema YAML under `db/gitlab_schemas/`.

### Database Sequences

- Rely on cluster-wide unique database sequences for `id` columns — uniqueness is enforced across all cells automatically.

### Unique Constraints

- DO NOT rely on database `UNIQUE` constraints for global uniqueness across cells — scope uniqueness indexes to include the `sharding_key` column instead.
- Use the Claim service only for the rare case where an attribute must be globally unique across all organizations and cells.

### Static Data

- DO NOT store static data in database tables that use auto-incrementing sequences as primary keys — inconsistent primary keys across cells cause reference clashes.
- Hard-code static data in application code using `ActiveRecord::FixedItemsModel::Model` instead of a database table; use `belongs_to_fixed_items` for associations with fixed-item models.
- Use globally unique references (not database sequences) when a cross-cell reference is unavoidable.

### Sharding Key Rules

- Give every row exactly one sharding key and choose the most specific key possible (prefer a key referencing `projects`, then `namespaces`, over `organization_id`); use a key referencing `users` only for `gitlab_main_user` tables.
- Ensure each row resolves to exactly one non-null, immutable sharding key so it remains attributable to one organization during isolation and migration.
- DO NOT use `namespace_id` as a sharding key when it refers to a `UserNamespace` — such rows can be `NULL`, violating the non-nullable requirement.
- Use `organization_id` as a sharding key only for root-level models (for example, `namespaces`) that do not belong to a project or namespace, and only after seeking approval from the Tenant Scale group.
- Allow multiple sharding key columns only when a check constraint ensures exactly one is non-null; DO NOT design new tables with multiple-column sharding keys unless absolutely necessary, as they may need to be split into separate tables in the future.
- When the sharding key value comes from a parent table that the table already references through a foreign key or loose foreign key to the same target, populate it via `desired_sharding_key.backfill_via.parent` in the `db/docs/` YAML and rely on the parent's reference; add a direct foreign key when no such parent chain exists or the direct reference intentionally identifies a different entity.
- Use `populate_sharding_key` in the model to ensure the sharding key is filled at the application level before save.
- Omit a direct foreign key on a sharding key when a foreign-key-backed parent chain carries the same key to the same target, or when the table automatically drops data via time-based partition retention (`retain_for`) or `sliding_list` partitioning; only retention-based omissions belong in `allowed_to_be_missing_foreign_key` in `spec/lib/gitlab/organizations/sharding_key_spec.rb`, with a comment explaining the retention behavior.
- When sharding a table by `organization_id`, register `supported`, `no_work_needed`, or a tracking issue in `config/organizations/transfer_support.yml`; require `supported` for new tables and implement applicable transfer logic with `update_organization_id_for`.
- Use `association(:common_organization)` in RSpec factories for models sharded by `organization_id` to ensure tests work without explicit organization setup.

### Cross-Schema References

- DO NOT make organization data depend on cell-local data without self-healing logic — the referenced cell-local data may not exist or may have different IDs after migration.
- When organization data must reference cell-local data, use a Loose Foreign Key (not a hard FK) and implement application logic to regenerate or gracefully handle missing references after migration.
- When cell-local data references organization data, use a regular foreign key.
- DO NOT persist identifiers in organization tables that may be inconsistent across cells (for example, IDs generated from auto-incrementing sequences in cell-local tables); use globally stable identifiers or avoid persisting computed references.

## Authoritative sources

For the full picture, see:

- doc/development/cells/_index.md
- doc/development/organization/sharding/_index.md

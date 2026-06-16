---
source_checksum: 3892981530d704dc
distilled_at_sha: f61a71870e300699d0cbf5f4ba05fb6666928907
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Cells Fundamentals Principles

## Checklist

### Compute Scope

- Scope all Web/API requests and Sidekiq workers to a single organization; convert cross-organization compute to be organization-scoped.
- DO NOT introduce cross-cell access to organization data — all data and compute for an organization must live on a single cell.

### Request Routing

- Ensure every cell-local service that accepts external requests is routable to the correct cell based on the organization the request is for.
- Apply the routable requirement to all request types and protocols, including Web, API, Git, and service-specific protocols (for example, KAS or the container registry).

### Organization Data Ownership

- Ensure organization data is migratable to another cell for all stateful cell-local services.
- Ensure every customer-data table in the GitLab Rails monolith has a traceable path to an organization through its sharding key.
- Define a sharding key on every new model that stores customer data so each row is attributable to a single organization.
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
- DO NOT use the deprecated `gitlab_main` schema — use `gitlab_main_org` instead.

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

## Authoritative sources

For the full picture, see:

- doc/development/cells/_index.md


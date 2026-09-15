---
source_checksum: 407cdd100d960bf1
distilled_at_sha: 586530a94f045df52e8ae3e37a72e449e7dd1e43
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Organizations Fundamentals Principles

## Checklist

### Feature Scoping

- Build features at the organization level only when users have a clear need for organization-level governance or configuration; anchor most features to the group, project, or user level instead.
- DO NOT use cross-group navigation as justification for creating an organization-level feature; scope such features at the group level with cross-group navigation.
- Confirm the use case with the Organizations team before building a feature at the organization level.

### Organization-Level Roles and Permissions

- Define what actions each organization role (Owner, User) can perform when designing an organization-level feature.
- DO NOT assume group-level roles map directly to organization-level roles.
- Consider whether your feature requires a new organization-level permission or whether an existing role is sufficient.

### GitLab.com TLG Requirements

- Require the top-level group (TLG) to transfer to its own organization for features that depend on organization context.
- DO NOT enforce TLG-in-own-organization with a check such as `organization.default?`; use organization-level permissions instead (for example, `organization_owner` and `organization_user` conditions in `Organizations::OrganizationPolicy`), because GitLab Self-Managed and GitLab Dedicated legitimately run inside the default organization.

### Billing Limitations

- DO NOT build features that depend on billing or subscription entitlements at the organization level; billing is currently scoped to the top-level group on GitLab.com, not to the organization.

### Feature Flags and Release Process

- Ship organization features behind an `organization flag` that advances through the fixed ladder of stages (Experimental → GA); follow the [Organizations release process](https://docs.gitlab.com/development/organizations/release_process/) for gating, registering, and advancing flags.

### `Current.organization` Setup

- Ensure `Current.organization` is set correctly at the request layer; it is set automatically in controllers, GraphQL, Grape API (via global `before_validation` hook), and Sidekiq.
- For Grape API classes that opt out of the global hook with `skip_global_organization_setup!`, derive the organization from the authenticated entity and set `Current.organization` explicitly in a `before` block.
- Set `Current.organization` explicitly in code that runs outside a request or Sidekiq context (Rake tasks, Rails console).
- Pass `Current.organization` from the request layer into service objects and other application logic that requires it (for example, `group_params.with_defaults(organization_id: Current.organization.id)`).

### Query Scoping and Data Isolation

- Ensure `Current.organization` is assigned before queries run against tables with a sharding key; the `gitlab-database-data_isolation` gem injects an additional `WHERE organization_id = ?` clause automatically when isolation is enabled.
- Use `Gitlab::Database::DataIsolation::ScopeHelper.without_data_isolation` only for intentional cross-organization data access (for example, admin tooling) or when the query modification causes poor performance.
- Note that `UPDATE`, `DELETE`, and `INSERT` statements are not isolated by the gem; only `SELECT` queries processed by ActiveRecord are scoped.

### Organization Routing

- Use regular, unscoped Rails URL helpers (for example, `projects_path`, `project_issues_path(@project)`) in views and links; the routing layer automatically nests the URL under the organization path when appropriate.
- Use explicit organization helpers (for example, `organization_projects_path(organization_path: 'my-org')`) outside the request layer — in services, workers, or Rake tasks — or when a caller needs an organization other than the one automatic resolution would pick.
- Pass `organization_path: nil` to a helper to force the plain global path only when `Current.data_context` does not resolve to an isolated organization; an isolated organization boundary takes precedence over this override.
- DO NOT hardcode or construct URLs on the frontend; follow the [URLs in GitLab frontend guidelines](https://docs.gitlab.com/development/urls_in_gitlab/#frontend-guidelines) to generate URLs correctly.

### `Current.data_context` and Isolation Boundary

- Understand that `Current.data_context` (not `Current.organization`) determines the data-isolation boundary: it resolves to an organization only when that organization is actually isolated (`Organization#isolated?` is true).
- Ensure that a user whose home organization is isolated always has that organization as the boundary, even when the request names a different organization.

### Frontend

- Access the current organization on the frontend via `window.gon.current_organization`; do not re-derive it from other sources.
- DO NOT pass the organization context manually to REST API or GraphQL requests; it is automatically included via the `X-GitLab-Organization-ID` header in `axios_utils.js` and `graphql.js`.

### Testing Organization Isolation

- Enable the `ui_for_organizations` and `org_stage_experimental` feature flags when testing organization-aware features.
- Pay special attention to cross-organization data leakage in: group and project member invites, user mentions, user search and autocomplete results, issue/MR/milestone/label cross-organization references, and finder classes scoping results to the current organization.
- Use the "Secret Tanuki" convention for manual isolation testing: create an organization named `Secret Tanuki` and prefix all associated data (users, projects, issues, groups, MRs) with that name, then search for `Secret Tanuki` in UI or API responses to detect unintended data exposure.
- Follow the automated testing strategies in [Testing with Organizations](https://docs.gitlab.com/development/testing_guide/testing_with_organizations/).

## Authoritative sources

For the full picture, see:

- doc/development/organization/_index.md
- doc/development/organization/query_scoping.md


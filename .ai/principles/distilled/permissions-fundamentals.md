---
source_checksum: a9ee8fe00bd4e2b4
distilled_at_sha: f22602e37afb92eb7028b601a922ebde417df6e4
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Permissions Fundamentals Principles

## Checklist

### Authorization Enforcement

- Enforce authorization using defense-in-depth: implement permission checks at multiple layers (finders, services, GraphQL, REST API, controllers).
- Enforce authorization in shared business logic (services and finders) as the primary layer, so checks are consistent across REST, GraphQL, and controllers.
- DO NOT rely solely on display-layer permission checks (such as showing/hiding buttons) as a security control — always back them with backend enforcement.
- Prefer domain logic (services or finders) as the source of truth when making exceptions to multi-layer enforcement.
- When a class accepts `current_user`, ensure it is responsible for authorization.
- When adding a new API endpoint, check an existing ability or add a new one; do not skip the authorization check.
- When using an ability check in UI elements, ensure the underlying backend code also performs the same ability check.
- Use `push_frontend_ability` (available on controllers inheriting from `ApplicationController`) to expose abilities to JavaScript; access them via `gon.abilities.<camelCaseName>` (DO NOT use `gon.abilities.<snake_case_name>`).

### Permission Naming Conventions

- Introduce a new permission only when no existing permission covers the same subject and action; reuse existing permissions wherever possible.
- Ensure every new permission enables the principle of least privilege: grant only the access required for a single, well-defined action on a single resource; split permissions that would bundle more than one action or unrelated capabilities. If you cannot scope the permission this narrowly, reconsider the design before introducing it.
- Follow the naming pattern `action_resource(_subresource)` for all permissions (both assignable and raw).
- Use only the preferred actions — `create`, `read`, `update`, `delete` — unless a documented exception applies; obtain Authorization team approval for any action outside this set.
- DO NOT introduce disallowed actions: `admin`, `change`, `configure`, `destroy`, `edit`, `list`, `manage`, `modify`, `set`, `view`, or `write`.
- Use the singular form for the resource segment (e.g., `read_project`, not `read_projects`).
- Match the resource name to the domain object being acted upon, using user-facing terminology rather than implementation details.
- DO NOT encode the resource boundary (`project`, `group`, `user`) into the permission name; pass the subject in the `can?` call to determine scope instead (e.g., use `read_insights_dashboard` not `read_project_insights_dashboard`).
- Introduce a new action outside the preferred set only when it represents a distinct lifecycle transition (`archive_project`), a relationship change (`transfer_project`), or a high-impact/irreversible operation (`purge_maven_virtual_registry_cache`) already established in GitLab domain language.

### Private Permissions

- Prefix private permissions with an underscore (`_`) following the pattern `_<action>_<qualifier>_<resource>` (e.g., `_read_authored_issue`).
- DO NOT check private permissions at enforcement points (controllers, services, finders, GraphQL); use them only inside policy files.
- Use private permissions when a role can perform an action only when a subject-level condition is met, or when different roles have different levels of access to the same action.
- DO NOT use private permissions for feature flag checks, license checks, or settings-based restrictions — use `prevent` rules instead.
- Create a definition file for every private permission under `config/authz/permissions/<resource>/_<action>_<qualifier>.yml`.
- Use qualifiers that correspond to a real attribute or relationship on the resource (e.g., `confidential`, `authored`, `assigned`); DO NOT use qualifiers that describe the actor.
- Prefer past-participle or adjective forms for qualifiers that read naturally as a description of the resource; introduce qualifiers only when the same action on the same resource requires different access levels depending on the resource's state.
- Declare a `conditionally_enables` field in every private permission YAML, listing the broader public permission(s) that imply it; use `null` when no public permission supersedes the private one (the validation task fails if this field is omitted).

### Role Definition YAML Files

- Define default roles as YAML files under `config/authz/roles/` with the fields `name`, `description`, `inherits_from`, and optionally `raw_permissions` and `permissions`.
- Understand that the final permission set for a role is the union of its `raw_permissions`, expanded `permissions` (assignable groups), and all permissions inherited recursively from parent roles.
- When adding a permission to a role, prefer using an assignable permission group; use `raw_permissions` only for existing permissions that need to be moved into the role definition.
- When removing a permission from a role, verify it is not depended on by other features; use `GITLAB_DEBUG_POLICIES=true` to trace where a permission is checked.

### Custom Roles

- Run `./ee/bin/custom-ability <ABILITY_NAME>` to generate the YAML configuration file for a new custom ability under `ee/config/custom_abilities/`.
- Run `bundle exec rails generate gitlab:custom_roles:code --ability <ABILITY_NAME>` to update the permissions validation schema and create a spec file.
- Define permissions declaratively in the custom ability YAML using `project_permissions` and `group_permissions` fields; DO NOT manually add policy rules to `ProjectPolicy` or `GroupPolicy` for custom abilities.
- Mark a custom ability as `wip: true` in its YAML when implementing across multiple MRs; remove the `wip:` key when the ability is ready to ship.
- Consolidate custom role abilities to a minimum: use `read_*` for all view-related actions and `admin_*` for object updates; avoid introducing additional abilities unless necessary.
- Ensure `admin_*` custom abilities declare `read_*` as a requirement in the YAML `requirements` field.
- Add the ability as a trait in the `MemberRoles` factory (`ee/spec/factories/member_roles.rb`) and add request specs under `ee/spec/requests/custom_roles/<ABILITY_NAME>/request_spec.rb`.
- Run `bundle exec rake gitlab:custom_roles:compile_docs` and `bundle exec rake gitlab:graphql:compile_docs` to update documentation after adding a custom ability.
- Assess privilege escalation risk when adding new custom permissions that interact with GitLab artifacts (such as access tokens) that encode the base role.

### Internal Permission Groups

- Define internal permission groups as YAML files under `config/authz/permission_groups/internal/<resource>/<name>.yml` with `description` and `permissions` fields.
- Use internal permission groups in `DeclarativePolicy` policies by calling `Authz::PermissionGroups::Internal.get('<identifier>')` and splatting the result into a `prevent` rule.
- Use internal permission groups when a resource state change (archiving, locking) should disable many permissions at once, or when the same permission set is referenced from multiple places.
- DO NOT use internal permission groups for role-based permission assignment (use role definitions or custom roles), or for token-scoped permissions (use assignable permissions).

### Predefined Roles and Visibility

- Store project membership (with group membership already resolved) in the `project_authorizations` table; the highest permission across group and project membership is the effective access level.
- DO NOT grant subgroups a higher visibility level than their parent group.
- Design complex feature permissions as separate, granular permissions with explicit dependency relationships rather than reusing a single broad permission.

### Policy Testing

- Place policy unit tests in `spec/policies/` (CE) or `ee/spec/policies/` (EE).
- Use one `describe` block per permission; DO NOT group multiple permissions into a single block.
- Use `where` table syntax to test each role explicitly, and include every role in the table — DO NOT omit roles expected to be disallowed.
- Define the subject explicitly inside each `describe` block using `let_it_be`; DO NOT rely on a subject defined at a higher scope.
- Use descriptively named fixtures that reflect the visibility or state under test (e.g., `private_project`, `archived_project`) rather than a generic `project`.
- Test both admin mode enabled (`:enable_admin_mode`) and admin mode disabled contexts for permissions that apply to admins.
- Test both feature flag disabled and licensed feature disabled contexts for every permission that is gated by either.

## Authoritative sources

For the full picture, see:

- doc/development/permissions/authorizations.md
- doc/development/permissions/conventions.md
- doc/development/permissions/role_definitions.md
- doc/development/permissions/predefined_roles.md
- doc/development/permissions/custom_roles.md
- doc/development/permissions/internal_permission_groups.md
- doc/development/permissions/testing_guidelines.md


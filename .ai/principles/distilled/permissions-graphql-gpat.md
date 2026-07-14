---
source_checksum: e6bdd4909ea096f0
distilled_at_sha: 73023e3b34aa63d1692e8a3066e870c10875ef55
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

> **Prerequisite:** If you haven't already, also read .ai/principles/distilled/permissions-fundamentals.md - it contains foundational rules that apply to all permissions work.

# Permissions: GraphQL Granular PAT Principles

## Checklist

### Permission Definition Files

- Use `bin/permission <permission_name>` to generate raw permission definition files; pass `-a` (action) and `-r` (resource) flags to override the default name-splitting behaviour when the action is more than one word.
- Place raw permission definition files at exactly `config/authz/permissions/<resource>/<action>.yml`; DO NOT add extra directories between the base path and the final filename.
- Ensure each permission definition file includes a `name` and `description` field; the `description` must follow the pattern `"Grants the ability to <action> <resource>"`.
- Include a `conditionally_enables` field for private (underscore-prefixed) permissions, set to the broader permission(s) that imply it, or `null` when none apply.
- Ensure each resource directory has a `.metadata.yml` with a valid `feature_category` entry from `config/feature_categories.yml`; look at existing API endpoints for that resource to find the correct category.
- Run `bundle exec rake gitlab:permissions:validate` (or rely on the Lefthook pre-push hook) to validate all permission definition files before pushing.

### Permission Naming

- Name permissions based on what the type **represents** or what the mutation **does**, not the GraphQL schema structure (e.g., `IssueType` → `read_issue`, `Mutations::Issues::Create` → `create_issue`).
- Use `read_<resource>` for object types, `create_<resource>` for create mutations, `update_<resource>` for update mutations, and `delete_<resource>` for delete mutations; use a specific permission name for special-action mutations (move, archive, transfer, etc.).
- Follow the Naming Permissions and Disallowed Actions conventions (see `.ai/principles/distilled/permissions-fundamentals.md` § Permission Naming Conventions) enforced by the validation Rake task.

### Assignable Permissions

- Create assignable permission YAML files manually at `config/authz/permission_groups/assignable_permissions/<category>/<resource>/<action>.yml`; DO NOT place them at any other path.
- Ensure every raw permission listed in an assignable permission's `permissions` array already exists as a raw permission definition file before referencing it.
- Set the `boundaries` field to only the organizational levels (`project`, `group`, `user`, `instance`) where the bundled raw permissions actually apply; use the principle of least privilege and DO NOT include boundaries that the endpoints do not support.
- Use `instance` boundary sparingly — typically only for admin-facing permissions.
- Add a category `.metadata.yml` only when titleization produces an incorrect display name (e.g., `ci_cd` → `"CI/CD"`); DO NOT create one when the folder name titleizes correctly.
- Add a resource `.metadata.yml` only when the resource name contains an acronym, brand name, or unconventional action that titleizes or pluralizes incorrectly, or when the generated description needs a custom noun.
- Include `<actions>` interpolation in any custom `description` field in a resource `.metadata.yml` so the action list stays in sync automatically.
- Ensure the `boundaries` field on an assignable permission covers the union of all `boundary_type` values declared by its raw permissions' endpoints and directives; the Lefthook pre-push validation catches mismatches.

### Assignable Permission Lifecycle

- DO NOT remove an assignable permission unless the underlying API functionality is also being removed; removal is a breaking change that causes tokens with that permission to silently lose access.
- DO NOT rename an assignable permission without a three-step migration: (1) add the new YAML file, queue a `rename_granular_scope_permission` batched background migration, and mark the old permission as `deprecated: true`; (2) finalize the batched background migration in a later milestone; (3) remove the deprecated file using `bundle exec rake gitlab:permissions:assignable:cleanup_deprecated`.
- DO NOT add raw permissions to an existing assignable permission except when adding support for new API endpoints; doing so immediately grants increased access to all existing tokens with that assignable permission.
- DO NOT remove raw permissions from an assignable permission without a migration strategy; removal immediately revokes access for all tokens holding that assignable permission.
- Prefer changing `boundary_type` between `project` and `group` (safe, because projects belong to groups); treat any change to or from `user` or `instance` as a breaking change requiring token holders to recreate their scopes.
- DO NOT rename a raw permission without updating both its definition file and every assignable permission YAML that references it; no database migration is required for raw permission renames.

### GraphQL Authorization Directives

- Add `authorize_granular_token` to every GraphQL object type and mutation that exposes protected resources; the `gitlab:permissions:graphql:validate` Rake task requires every object type to declare either a directive or a `skip_reason:`.
- Use `boundary: :project` (or `:group`, `:user`, `:instance`) on object types where the resolved object has a method to reach the boundary (e.g., `issue.project`); use `boundary_argument: :project_path` on mutations and root query fields where the boundary is passed as an argument.
- Use `boundary: :itself` when the type itself is the boundary object (e.g., `ProjectType` or `GroupType`).
- Use `boundary: :user` or `boundary: :instance` for standalone resources that do not belong to a specific project or group.
- When a mutation's `boundary_argument` resolves to a record that is not itself a Project or Group, combine `boundary_argument` with `boundary` so the extractor locates the record and then calls `boundary` on it to reach the Project or Group.
- Ensure `permissions` references only valid permission symbols from `Authz::PermissionGroups::Assignable.all_permissions`; the `gitlab:permissions:validate` Rake task enforces this.
- Ensure `boundary_type` matches at least one boundary declared in the corresponding assignable permission's `boundaries` field; the Lefthook pre-push validation catches mismatches.
- DO NOT declare `permissions:` alongside `skip_reason:`; use `skip_reason:` alone on types that intentionally opt out of granular-token authorization.
- Use `traversal: true` on entry-point fields (e.g., `Query.group(fullPath:)`, `Query.project(fullPath:)`) that resolve a boundary from a path argument but do not expose data themselves; pass it via `granular_scope_directive(traversal: true)` on the field definition. Note: `traversal: true` only applies to `project` and `group` boundary types and is not currently enforced — a field marked `traversal: true` enforces the listed permissions like any other field pending reimplementation.
- DO NOT pass `traversal: true` to a type-level `authorize_granular_token`; use `granular_scope_directive(traversal: true)` on the field definition instead (passing it at the type level raises `ArgumentError`).

### Traversal Between Authorized Types

- Understand that when a field on an authorized type returns another type that also declares `authorize_granular_token`, the owner type's directive is intended to be automatically skipped and the child type's directive enforces authorization; however, this automatic skip is **not currently performed** — plan permissions assuming both the owner type's and the child type's directives are enforced.
- DO NOT rely on the automatic traversal skip for leaf types (types whose fields all return plain scalars, e.g., `RepositoryLanguageType`, `PushRulesType`); for leaf types the collection-level check always fires and must not be bypassed.
- Add an explicit field-level directive using `directives: granular_scope_directive(...)` to any field where the automatic traversal skip should not apply; an explicit field-level directive always wins.

### Authorization Caching and Performance

- Rely on the per-request authorization cache: multiple fields that resolve to the same boundary and permissions reuse the cached result, so the authorization service runs only once for them.
- Understand that `BoundaryExtractors::Preloader` batch-loads boundary associations across all nodes in a collection before authorization runs, avoiding N+1 queries (e.g., `issue.project` for each resolved issue); the loaded records are cached in `Gitlab::SafeRequestStore` and reused by the boundary extractors.
- Understand that legacy (non-granular) PATs skip granular authorization entirely; granular authorization only runs when the token is granular. Exception: when a boundary's root namespace has `granular_tokens_enforced?` enabled, legacy tokens are held to the same permission checks as granular tokens.

### Feature Flag

- Ensure the `granular_personal_access_tokens` feature flag is enabled for the token's user during development and testing; when the flag is disabled, granular PATs do not work for GraphQL requests.

### Authorization Tests

- Use the `'authorizing granular token permissions for GraphQL'` shared example for both query and mutation specs; provide `user`, `boundary_object`, and `request` let-bindings.
- Set `boundary_object` to match the `boundary_type`: `project` for `:project`, `group` for `:group`, `:user` for `:user`, `:instance` for `:instance`.
- Ensure the `user` is a member of the `boundary_object` namespace (project or group) when the boundary type is `:project` or `:group`; authorization is denied otherwise.
- Verify that the shared example covers: legacy PATs still grant access, granular PATs with the required permission grant access, granular PATs without the required permission are denied, and the `granular_personal_access_tokens` feature flag is enforced.

## Authoritative sources

For the full picture, see:

- doc/development/permissions/granular_access/_index.md
- doc/development/permissions/granular_access/graphql_implementation_guide.md
- doc/development/permissions/granular_access/graphql_architecture.md
- doc/development/permissions/granular_access/permission_definitions.md
- doc/development/permissions/granular_access/assignable_permissions.md


---
source_checksum: 4245f8c78c51bf39
distilled_at_sha: 186bab0afd636fbcfc444beff09e9b796060fcea
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

> **Prerequisite:** If you haven't already, also read .ai/principles/distilled/permissions-fundamentals.md - it contains foundational rules that apply to all permissions work.

# Permissions: GraphQL Granular PAT Principles

## Checklist

### Permission Definition Files

- Use `bin/permission <permission_name>` to generate raw permission definition files; pass `-a` (action) and `-r` (resource) flags to override the default name-splitting behaviour when the action is more than one word.
- Place raw permission definition files at exactly `config/authz/permissions/<resource>/<action>.yml`; DO NOT add extra directories between the base path and the final filename.
- Ensure each permission definition file includes a `name` and `description` field; the `description` must follow the pattern `"Grants the ability to <action> <resource>"`.
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

- Add `authorize_granular_token` to every GraphQL object type and mutation that exposes protected resources; all fields accessed with granular PATs must have a directive or the authorization service returns `"Unable to determine boundaries and permissions for authorization"`.
- Use `boundary: :project` (or `:group`, `:user`, `:instance`) on object types where the resolved object has a method to reach the boundary (e.g., `issue.project`); use `boundary_argument: :project_path` on mutations and root query fields where the boundary is passed as an argument.
- Use `boundary: :itself` when the type itself is the boundary object (e.g., `ProjectType` or `GroupType`).
- Use `boundary: :user` or `boundary: :instance` for standalone resources that do not belong to a specific project or group.
- DO NOT apply `boundary` (without `:id` argument) to root query fields that lack an `:id` argument — the object is not yet resolved and an `ArgumentError` will be raised; use `boundary_argument` instead.
- Ensure `permissions` references only valid permission symbols from `Authz::PermissionGroups::Assignable.all_permissions`; the `gitlab:permissions:validate` Rake task enforces this.
- Ensure `boundary_type` matches at least one boundary declared in the corresponding assignable permission's `boundaries` field; the Lefthook pre-push validation catches mismatches.
- Apply the directive at only one level per field (field, owner type, implementing type, or return type) to avoid ambiguity; the `DirectiveFinder` stops at the first match in that priority order.
- DO NOT declare `permissions: []` on a directive; the authorization service returns `"Unable to determine permissions for authorization"` when the permissions array is empty.
- Use `traversal: true` on entry-point fields (e.g., `Query.group(fullPath:)`, `Query.project(fullPath:)`) that resolve a boundary from a path argument but do not expose data themselves; this causes the authorization service to verify only that the token is scoped to the boundary, not the listed permission. Note: `traversal: true` only applies to `project` and `group` boundary types.

### Directive Discovery and Boundary Extraction

- Understand that `DirectiveFinder` checks directives in this priority order and returns the first match: field-level → owner type → implementing type → return type (unwrapping List, NonNull, and Connection wrappers).
- Understand that `BoundaryExtractor` uses Strategy A (`boundary_argument`) for mutations and query fields with path arguments, Strategy B (`boundary` method on resolved object) for type fields, Strategy C (ID fallback via GlobalID) for query fields with an `:id` argument when the object is nil, and Strategy D (standalone `NilBoundary`) for `user` or `instance` boundaries.
- Be aware that the ID fallback strategy (Strategy C) fetches the record twice — once for authorization and once during field resolution — though the query is cached.
- Ensure that `boundary` method values are one of the valid accessor methods: `project`, `group`, or `itself`; any other value raises `ArgumentError: "Invalid boundary method: '<value>'"`.

### Traversal Between Authorized Types

- Understand that when a field on an authorized type returns another type that also declares `authorize_granular_token`, the owner type's directive is automatically skipped; the child type's directive enforces authorization when fields on the child object are resolved.
- DO NOT rely on the automatic traversal skip for leaf types (types whose fields all return plain scalars, e.g., `RepositoryLanguageType`, `PushRulesType`); for leaf types the collection-level check always fires and must not be bypassed.
- Add an explicit field-level directive using `directives: granular_scope_directive(...)` to any field where the automatic traversal skip should not apply; an explicit field-level directive always wins.

### Authorization Caching and Performance

- Rely on the per-request `context[:authz_cache]` Set to avoid redundant authorization checks; the cache key is `[permissions.sort, boundary.class, boundary.namespace.id]`, so multiple fields on the same type and boundary incur only one authorization service call.
- Understand that non-granular (legacy) PATs skip the entire `GranularTokenAuthorization` extension with zero overhead; granular authorization only runs when `token.granular?` is true.
- Understand that mutation response fields (e.g., `createIssue.issue`) and permission metadata fields (e.g., `issue.userPermissions`) are automatically skipped by `SkipRules`; DO NOT add directives to these fields.

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


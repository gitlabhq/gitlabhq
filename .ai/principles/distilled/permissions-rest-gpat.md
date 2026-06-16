---
source_checksum: 4dd2031b74a69933
distilled_at_sha: 4bdca94fd505e9510cf535c34f2343e7b91332fe
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

> **Prerequisite:** If you haven't already, also read .ai/principles/distilled/permissions-fundamentals.md - it contains foundational rules that apply to all permissions work.

# Permissions REST GPAT Principles

## Checklist

### Permission Definition Files

- Generate raw permission definition files using the `bin/permission` command rather than creating them manually.
- Place raw permission definition files at exactly `config/authz/permissions/<resource>/<action>.yml`; DO NOT add extra directories between the base path and the filename.
- Name permissions based on what the endpoint **modifies or returns**, not the route structure (e.g., `DELETE /projects/:id/jobs/:job_id/artifacts` → `delete_job_artifact`).
- Use a single `read_<resource>` permission for both list and show (GET) operations on the same resource.
- Include the parent resource in the permission name for nested resources (e.g., `create_pipeline_schedule_variable`).
- Create specific permissions for special actions (cancel, retry, download, trigger); DO NOT collapse them into a generic update permission.
- Use a single `update_<resource>` permission covering all attribute updates; DO NOT create per-attribute permissions such as `update_issue_title`.
- Set `feature_category` in the resource `.metadata.yml` to a valid entry from `config/feature_categories.yml`; look at existing endpoints in the same API file for the correct value.
- Run `bundle exec rake gitlab:permissions:validate` (or rely on the Lefthook pre-push hook) to catch naming and structure violations before pushing.

### Assignable Permissions

- Place assignable permission YAML files at exactly `config/authz/permission_groups/assignable_permissions/<category>/<resource>/<action>.yml`; DO NOT add extra directories.
- Ensure every raw permission listed in an assignable permission's `permissions` array already exists as a raw permission definition file before referencing it.
- Select `boundaries` based only on the organizational levels the bundled raw permissions actually support; DO NOT include boundaries where the permissions do not apply.
- Include `project` in `boundaries` when raw permissions cover `/projects/:id/...` endpoints; include `group` for `/groups/:id/...` endpoints; include `user` for `/users/:id/...` or personal-namespace operations; use `instance` sparingly and only for admin-facing permissions.
- Create a category `.metadata.yml` only when titleization produces an incorrect display name (e.g., `ci_cd` → "CI/CD"); DO NOT create one when the folder name titleizes correctly.
- Create a resource `.metadata.yml` only when the resource name contains an acronym, brand name, or awkward pluralization; DO NOT create one when the directory name titleizes and pluralizes correctly.
- Use `<actions>` interpolation in a resource `.metadata.yml` description so the action list stays in sync automatically.
- DO NOT remove an assignable permission while the underlying API functionality still exists; removal is a **breaking change** that silently drops all access for tokens holding that permission.
- DO NOT rename an assignable permission without following the three-step migration process: add the new YAML, queue a `rename_granular_scope_permission` batched background migration, mark the old permission `deprecated: true`, finalize the migration in a later milestone, then delete the deprecated file using `bundle exec rake gitlab:permissions:assignable:cleanup_deprecated`.
- DO NOT add raw permissions to an existing assignable permission except when adding support for new API endpoints.
- DO NOT remove raw permissions from an assignable permission without using a rename migration to split the old permission into the retained and moved parts.
- Changing `boundary_type` between `project` and `group` is safe; changing to or from `user` or `instance` is a **breaking change** requiring token holders to recreate scopes.
- Renaming a raw permission requires only updating the raw permission YAML and any referencing assignable permission YAMLs; DO NOT create a database migration for raw permission renames.

### REST API Endpoint Decorators

- Add `route_setting :authorization` immediately before every HTTP method definition (`get`, `post`, `put`, `delete`), even when multiple endpoints share the same permission.
- Use `boundary_type: :project | :group | :user | :instance` for single-boundary endpoints; use the `boundaries` array for endpoints that support multiple boundary types.
- Use the `boundary` option (a callable returning the boundary object) only when the boundary cannot be determined through standard parameter lookup.
- Use `boundary_param` when the request parameter containing the boundary identifier is not the default `:id`.
- When using `boundaries` array, include a `boundary_type` key in each entry and optionally a `boundary_param`; the system evaluates boundaries in priority order `project` > `group` > `user` > `instance` and uses the first resolvable boundary.
- Use `skip_granular_token_authorization: true` only for endpoints that are publicly accessible, authenticate by means other than PATs, or where authentication is optional; DO NOT use it to bypass permission checks on authenticated endpoints.
- Add permissions that represent read-only access to publicly visible data to `config/authz/roles/public_anonymous.yml` under the matching `project:` or `group:` boundary so that granular PATs without an explicit scope can access them on public resources; DO NOT add `user` or `instance` boundary permissions to this file.

### Testing

- Add the `'authorizing granular token permissions'` shared example for every endpoint, providing `boundary_object`, `user`, and `request` let-bindings.
- Set `boundary_object` to match the `boundary_type`: `project` → `project`, `group` → `group`, `:user` → `:user`, `:instance` → `:instance`.
- Ensure the `user` is a member of the namespace (project or group) when the boundary object is a project or group.

### Job Token Permissions

- Ensure all new job token permissions are opt-in and disabled by default.
- Tag `@gitlab-com/gl-security/product-security/appsec` for security review before merging any new job token permission.
- Update all three locations when adding a new job token permission: `lib/ci/job_token/policies.rb`, `app/validators/json_schemas/ci_job_token_policies.json`, and `app/assets/javascripts/token_access/constants.js`.
- Add `route_setting :authentication, job_token_allowed: true` and `route_setting :authorization, job_token_policies: <policy>` to each endpoint that should accept job token authentication.
- Use `:read_*` policies for GET (read) operations and `:admin_*` policies for POST/PUT/DELETE (write/delete) operations on job token endpoints.
- Use the `allow_public_access_for_enabled_project_features` parameter on `route_setting :authorization` to allow job token access based on project feature visibility, providing backward compatibility.
- Use the `'enforcing job token policies'` shared RSpec example to test job token authorization, passing the required policy and optionally `allow_public_access_for_enabled_project_features` and `expected_success_status`.
- Regenerate the fine-grained permissions documentation after adding job token support to a new endpoint by running `bundle exec rake ci:job_tokens:compile_docs`.

## Authoritative sources

For the full picture, see:

- doc/development/permissions/granular_access/rest_api_implementation_guide.md
- doc/development/permissions/granular_access/job_tokens.md
- doc/development/permissions/job_tokens.md
- doc/development/permissions/granular_access/permission_definitions.md
- doc/development/permissions/granular_access/assignable_permissions.md


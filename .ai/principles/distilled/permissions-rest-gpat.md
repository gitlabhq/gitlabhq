---
source_checksum: f04d2025bf3b6e5f
distilled_at_sha: da75f7373628b035becb13fb3f0d21b4b3d3690f
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

> **Prerequisite:** If you haven't already, also read .ai/principles/distilled/permissions-fundamentals.md - it contains foundational rules that apply to all permissions work.

# Permissions REST GPAT Principles

## Checklist

### Permission Definition Files

- Generate raw permission definition files using the `bin/permission` command rather than creating them manually.
- Place raw permission definition files at exactly `config/authz/permissions/<resource>/<action>.yml`; DO NOT add extra directories between the base path and the filename.
- When the permission name contains a multi-word action (e.g., `force_delete_ai_catalog_item`), pass `-a <action> -r <resource>` flags to `bin/permission` to override the default split; otherwise the command places the file under the wrong resource directory.
- Name permissions based on what the endpoint **modifies or returns**, not the route structure (e.g., `DELETE /projects/:id/jobs/:job_id/artifacts` → `delete_job_artifact`).
- Use a single `read_<resource>` permission for both list and show (GET) operations on the same resource.
- Include the parent resource in the permission name for nested resources (e.g., `create_pipeline_schedule_variable`).
- Create specific permissions for special actions (cancel, retry, download, trigger); DO NOT collapse them into a generic update permission.
- Use a single `update_<resource>` permission covering all attribute updates; DO NOT create per-attribute permissions such as `update_issue_title`.
- Set `feature_category` in the resource `.metadata.yml` to a valid entry from `config/feature_categories.yml`; look at existing endpoints in the same API file for the correct value.
- Set `conditionally_enables` in the permission definition for any private (underscore-prefixed) permission; use `null` when no broader permission implies it.
- Run `bundle exec rake gitlab:permissions:validate` (or rely on the Lefthook pre-push hook) to catch naming and structure violations before pushing.

### Assignable Permissions

- Prefer adding raw permissions to an existing assignable permission over creating a new one; only create a new assignable permission when the raw permissions represent a capability users should be able to grant separately from existing assignable permissions for that resource.
- Place assignable permission YAML files at exactly `config/authz/permission_groups/assignable_permissions/<category>/<resource>/<action>.yml`; DO NOT add extra directories.
- Ensure every raw permission listed in an assignable permission's `permissions` array already exists as a raw permission definition file before referencing it.
- Set `available_for` to `granular_access_token`, `role`, or both; an assignable permission declaring `granular_access_token` must have at least one of its raw permissions referenced by a REST authorization decorator or GraphQL granular scope directive.
- Select `boundaries` based only on the organizational levels the bundled raw permissions actually support; DO NOT include boundaries where the permissions do not apply.
- Include `project` in `boundaries` when raw permissions cover `/projects/:id/...` endpoints; include `group` for `/groups/:id/...` endpoints; include `user` for `/users/:id/...` or personal-namespace operations; use `instance` sparingly and only for admin-facing permissions.
- Create a category `.metadata.yml` only when titleization produces an incorrect display name (e.g., `ci_cd` → "CI/CD"); DO NOT create one when the folder name titleizes correctly.
- Create a resource `.metadata.yml` only when the resource name contains an acronym, brand name, or awkward pluralization; DO NOT create one when the directory name titleizes and pluralizes correctly.
- Use `<actions>` interpolation in a resource `.metadata.yml` description so the action list stays in sync automatically.
- Use the optional `assignable_when` field to declare conditions (e.g., `admin`, `saas`, `self_managed`, `gitlab_team_member`) a user must meet for the permission to appear in the token creation UI at a given boundary; tag the corresponding REST endpoints with `assignable_when` in the same merge request, because the validation task fails when endpoint tags and YAML conditions disagree.
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
- Use `additional_scopes` when an endpoint acts on a second container (e.g., a move-issue endpoint that writes to a target project): declare each additional container's `permissions` and `boundary_type`, plus `boundary_param` or a callable `boundary`; every entry must authorize successfully or the request is denied with `404 Not Found`. A `:project` or `:group` entry without `boundary_param` or `boundary` is rejected by `gitlab:permissions:validate`.
- Use `assignable_when: [:admin]` (or other conditions) on the `route_setting :authorization` decorator when the endpoint restricts access beyond membership (e.g., `authenticated_as_admin!`); update the corresponding assignable permission YAML in the same merge request.
- Use `skip_granular_token_authorization: :<reason>` (a symbol naming the reason, e.g., `:public_endpoint`) only for endpoints that are publicly accessible, authenticate by means other than PATs, or where authentication is optional; DO NOT use it to bypass permission checks on authenticated endpoints, and DO NOT pass `true` — the reason must be a key defined in `lib/tasks/gitlab/permissions/routes/skip_reasons.rb` (add a new key with a human-readable label if no existing reason fits).
- Use `todo: '<issue-link-or-reason>'` (a non-empty string) to defer granular token authorization when you have not yet decided how it should work for an endpoint; granular PATs receive `403 Forbidden` while legacy PATs are unaffected. Replace `todo` with `permissions` + `boundary_type` (or `skip_granular_token_authorization`) once the decision is made. DO NOT leave `todo` blank — the validation task fails on a blank value.
- Add permissions that represent read-only access to publicly visible data to `config/authz/roles/public_anonymous.yml` under the matching `project:` or `group:` boundary so that granular PATs without an explicit scope can access them on public resources; DO NOT add `user` or `instance` boundary permissions to this file.

### Testing

- Add the `'authorizing granular token permissions'` shared example for every endpoint, providing `boundary_object`, `user`, and `request` let-bindings.
- Set `boundary_object` to match the `boundary_type`: `project` → `project`, `group` → `group`, `:user` → `:user`, `:instance` → `:instance`.
- Ensure the `user` is a member of the namespace (project or group) when the boundary object is a project or group.
- Pass `expected_success_status:` as a keyword argument to the shared example when the success response is not `:success` (e.g., `:created`, `:accepted`, `:no_content`, `:redirect`).
- Pass `legacy_token_scopes:` as a keyword argument when the endpoint requires legacy token scopes other than the default `%w[api]`.
- Ensure the `request` block supplies valid `params` and that any resource the request path references exists, so the "granting access" assertion receives a real success response.
- For endpoints declaring `additional_scopes`, pass `additional_scope_permissions:` to the shared example and define `additional_scope_requirements` let-bindings; the shared example adds an assertion that a token holding only the primary boundary's scope is denied.

### Documentation and Validation

- Regenerate the fine-grained token reference documentation by running `bundle exec rake gitlab:permissions:routes:compile_docs` after adding or changing REST API endpoint authorization; DO NOT edit `doc/auth/tokens/fine_grained_access_tokens_rest.md` by hand.

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
- doc/development/permissions/granular_access/permission_definitions.md
- doc/development/permissions/granular_access/assignable_permissions.md


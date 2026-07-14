---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: REST API implementation guide
---

To reduce the security impact of compromised Personal Access Tokens (PATs), granular or fine-grained PATs allow users to create tokens with fine-grained permissions limited to specific organizational boundaries (groups, projects, user, or instance-level). This enables users to follow the principle of least privilege by granting tokens only the permissions they need.

Granular PATs allow fine-grained access control through granular scopes that consist of a boundary and specific resource permissions. When authenticating API requests with a granular PAT, GitLab validates that the token's permissions include access to the requested resource at the specified boundary level.

This documentation is designed for community contributors and GitLab developers who want to make REST API endpoints compliant with granular PAT authorization.

## Step-by-Step Implementation Guide

This guide walks you through adding granular PAT authorization to REST API endpoints. Before starting, review the [Permission Naming Conventions](../conventions.md) documentation to understand the terminology used throughout.

> [!note]
> These steps cover REST API endpoints only. For adding support to GraphQL queries and mutations, refer to the [GraphQL implementation guide](graphql_implementation_guide.md).

### Workflow Overview

The implementation follows this flow:

1. **Step 1-2:** Plan - Identify endpoints and design permissions
1. **Step 3:** Create raw permissions (YAML files)
1. **Step 4:** Bundle raw permissions into assignable permissions (YAML files)
1. **Step 5:** Add authorization decorators to endpoints (Ruby code)
1. **Step 6:** Write authorization tests (Ruby specs)
1. **Step 7:** Test locally (manual validation)
1. **Step 8:** Validate and regenerate documentation (Rake tasks)

### Files Created by Each Step

Quick reference showing what you create in each step:

| Step | File Type | Location | Quantity | Example |
|------|-----------|----------|----------|---------|
| 2 | Planning document | (mental notes) | — | Permission names identified |
| 3 | Raw permission YAML | `config/authz/permissions/<resource>/<action>.yml` | 1 per permission | `config/authz/permissions/job/read.yml` |
| 3 | Raw permission resource metadata | `config/authz/permissions/<resource>/.metadata.yml` | 1 per resource | `config/authz/permissions/job/.metadata.yml` |
| 4 | Assignable permission YAML | `config/authz/permission_groups/assignable_permissions/<category>/<resource>/<action>.yml` | 1 per group | `config/authz/permission_groups/assignable_permissions/ci_cd/job/run.yml` |
| 4 (optional) | Category metadata | `config/authz/permission_groups/assignable_permissions/<category>/.metadata.yml` | 0 or 1 per category | `config/authz/permission_groups/assignable_permissions/ci_cd/.metadata.yml` |
| 4 | Resource metadata | `config/authz/permission_groups/assignable_permissions/<category>/<resource>/.metadata.yml` | 1 per resource | `config/authz/permission_groups/assignable_permissions/ci_cd/job/.metadata.yml` |
| 5 | Grape decorators | Modify `lib/api/<resource>.rb` | 1 per endpoint | Added `route_setting :authorization` |
| 6 | RSpec tests | Modify `spec/requests/api/<resource>_spec.rb` | 1 per endpoint | Added `it_behaves_like 'authorizing...'` |
| 8 | Generated reference documentation | `doc/auth/tokens/fine_grained_access_tokens_rest.md` | 1 | Regenerated with `bundle exec rake gitlab:permissions:routes:compile_docs` |

### Step 1: Identify REST API Endpoints for the Resource

**Goal:** Find all REST API endpoints for the resource you're working on.

1. Locate the API file for your resource in `lib/api/<resource_name>.rb`.

   Example: For the jobs resource, open `lib/api/ci/jobs.rb`

   **Tips:**
   - Some resources may have endpoints spread across multiple API files (e.g., nested resources)
   - Check for `resources :resource_name do` blocks that define nested endpoints
   - Look at the router to understand the full scope of endpoints for your resource

1. Identify all HTTP method/route pairs in the file. Document each endpoint with its HTTP verb:

   ```ruby
   get ':id/jobs'
   get ':id/jobs/:job_id'
   post ':id/jobs/:job_id/cancel'
   post ':id/jobs/:job_id/retry'
   delete ':id/jobs/:job_id/artifacts'
   ```

1. Check if any endpoints already have authorization decorators (`route_setting :authorization`). You'll need to:
   - Add decorators to endpoints that don't have them
   - Update decorators for endpoints that have incomplete or incorrect permissions

> [!note]
> These endpoints are the basis for the raw permissions you'll create in the next step. Each unique operation (HTTP verb + route) typically needs its own permission.

### Step 2: Determine Permissions Needed

**Goal:** Define granular permissions following GitLab naming conventions.

For the naming conventions, see [Naming Permissions](../conventions.md#naming-permissions) in the conventions documentation.

#### Determining the Resource Name for Endpoints

When implementing granular PAT authorization, name permissions based on what the endpoint **modifies or returns**, not the route structure.

**Examples:**

- Endpoint `DELETE /projects/:id/jobs/:job_id/artifacts` → modifies `artifacts` → permission name is `delete_job_artifact`
- Endpoint `GET /projects/:id/issues` → returns `issues` → permission name is `read_issue`
- Endpoint `POST /projects/:id/jobs/:job_id/cancel` → modifies the `job` status → permission name is `cancel_job`

#### Common Patterns

- **List and Show operations**: Use a single `read_resource` permission for both
  - `GET /projects/:id/jobs` → `read_job`
  - `GET /projects/:id/jobs/:job_id` → `read_job`
- **Nested resources**: Include the parent resource in the permission name
  - `POST /projects/:id/pipeline_schedules/:pipeline_schedule_id/variables` → `create_pipeline_schedule_variable`
- **Special actions**: Create specific permissions for unique operations
  - Cancel, retry, download, trigger, etc. each get their own permission
- **Attribute updates**: Use a single update permission covering all attributes
  - `update_issue` covers updating title, description, assignees, etc.
  - Do not create `update_issue_description`, `update_issue_title`

### Step 3: Create Permission Definition Files

**Goal:** Create YAML definition files for each permission, if they don't exist yet.

Follow the instructions in the [Permission Definition File](permission_definitions.md#permission-definition-file) section to create raw permission YAML files using the `bin/permission` command.

### Step 4: Create or Update Assignable Permissions

**Goal:** Bundle raw permissions into assignable permissions for a simpler user experience.

Prefer to add your raw permissions to an existing assignable permission instead of creating a new one,
wherever that makes sense. Assignable permissions are user-facing: each new one is displayed in the
token creation UI, and its name is stored in the database for every token that selects it.
If you remove or rename an assignable permission later, it is a breaking change, while a raw permission
inside an existing assignable permission can be renamed or moved freely. Only create a new
assignable permission when the raw permissions represent a capability that users should be able to
grant separately from the existing assignable permissions for that resource. For the impact of each
kind of change, see
[Maintaining Assignable Permissions](assignable_permissions.md#maintaining-assignable-permissions).

Follow the instructions in the [Assignable Permissions](assignable_permissions.md) documentation to create or update assignable permission YAML files.

### Step 5: Add Authorization Decorators to API Endpoints

For each endpoint, add the `route_setting :authorization` decorator immediately before the route definition:

```ruby
route_setting :authorization, permissions: :read_job, boundary_type: :project
get ':id/jobs' do
  # endpoint implementation
end
```

#### Decorator Options

| Option | Description |
|--------|-------------|
| `permissions` | The permission(s) required for this endpoint (symbol or array of symbols) |
| `boundary_type` | The boundary type for single-boundary endpoints: `:project`, `:group`, `:user`, or `:instance` |
| `boundary_param` | Optional. The request parameter containing the boundary identifier. Defaults to `:project_id` with a fallback to `:id` for projects, and `:group_id` with a fallback to `:id` for groups |
| `boundaries` | Alternative to `boundary_type` for endpoints supporting multiple boundaries (see below) |
| `boundary` | Alternative to `boundary_type` for endpoints where the boundary cannot be determined through standard parameter lookup. A callable object (proc, lambda, or method) that returns the boundary object |
| `skip_granular_token_authorization` | Optional. A symbol naming the reason why granular PATs can access the endpoint without requiring specific permissions, for example `:public_endpoint` (see below) |

Example with custom `boundary_param`:

```ruby
route_setting :authorization, permissions: :read_job, boundary_type: :project, boundary_param: :project_id
get 'jobs' do
  # endpoint uses params[:project_id] instead of params[:id]
end
```

Example using `boundary`:

```ruby
def registry
  ::VirtualRegistries::Packages::Maven::Registry.find(params[:id])
end

route_setting :authorization, permissions: :download_maven_package_file, boundary: -> { registry.group }, boundary_type: :group
get '/api/v4/virtual_registries/packages/maven/:id/*path' do
  # Boundary cannot be determined through `params`. Instead, it is determined
  # from an object (registry) fetched using an ID from the endpoint's
  # parameters.
end
```

#### Multiple Boundaries per Endpoint

Some endpoints may need to support multiple boundary types. For example, an import endpoint might work at the group level when importing into a group namespace, or at the user level when importing into a personal namespace. In these cases, use the `boundaries` option instead of `boundary_type` or `boundary`:

```ruby
route_setting :authorization, permissions: :create_bitbucket_import,
  boundaries: [{ boundary_type: :group, boundary_param: :target_namespace }, { boundary_type: :user }]
post 'import/bitbucket' do
  # endpoint implementation
end
```

When multiple boundaries are defined:

- Each boundary in the array requires a `boundary_type` key and optionally a `boundary_param` key to specify which request parameter contains the boundary identifier
- Every boundary that can be resolved from the request parameters is considered (`user` and `instance` boundaries always resolve)
- The resolved boundaries are evaluated in priority order (`project` > `group` > `user` > `instance`) and access is granted when the token's scopes grant all required permissions on any one of them

#### Skipping Granular Token Authorization

Some endpoints don't require authentication and are publicly accessible, or do not implement token authentication. Since token authentication is skipped for these endpoints, defining granular permissions doesn't make sense. However, to maintain coverage tracking for all endpoints, use the `skip_granular_token_authorization` option with a symbol that names the reason for skipping:

```ruby
route_setting :authorization, skip_granular_token_authorization: :public_endpoint
get 'public-endpoint' do
  # endpoint implementation
end
```

The reason must be one of the keys defined in `lib/tasks/gitlab/permissions/routes/skip_reasons.rb`. The validation Rake task rejects unknown reasons. If no existing reason fits your endpoint, add a new key with a human-readable label to that file.

**When to use `skip_granular_token_authorization`:**

- Public endpoints that don't require authentication, including discovery or metadata endpoints (`:public_endpoint`)
- Endpoints that authenticate by other means than personal access tokens (for example, `:runner_token_auth`, `:job_token_auth`, or `:geo_jwt_auth`)
- Endpoints where authentication is optional and the response is the same regardless

Adding this decorator ensures that all endpoints are explicitly covered by the authorization system, even those that don't require permissions.

#### Allowing Access on Publicly Visible Resources

Permissions listed in `config/authz/roles/public_anonymous.yml` are granted to a fine-grained PAT, even one without a matching scope, when the target Project or Group is publicly visible and the relevant feature is enabled. This mirrors the access an anonymous caller has on the same resource: `Authz::BoundaryPolicy` grants a permission on the boundary whenever `Users::Anonymous` is allowed that same permission on the underlying Project or Group.

To opt a permission into this behavior, add it under the matching boundary (`project:` or `group:`) in `config/authz/roles/public_anonymous.yml`:

```yaml
project:
  permissions: []
  raw_permissions:
    - read_release
group:
  permissions: []
  raw_permissions:
    - read_subgroup
```

**When to opt in:**

- The permission represents read-only access to data that is already visible to anonymous callers on a public Project or Group.
- The permission is gated behind a `ProjectFeature` (for example `repository`, `issues`) so that disabling the feature still prevents access.

The bypass is gated to `:project` and `:group` boundaries. `:user` and `:instance` boundaries do not consult `public_anonymous.yml`.

**Important Notes:**

- Add the decorator to **every endpoint** individually, even if multiple endpoints use the same permission
- The decorator goes **immediately before** the HTTP method definition (`get`, `post`, `put`, `delete`)
- Use the exact permission name (symbol) defined in your YAML files
- Use `boundary_type` or `boundary` for single-boundary endpoints; use `boundaries` array for multi-boundary endpoints
- Use `skip_granular_token_authorization` exclusively for endpoints that are unauthenticated or authenticate by other means than a personal access token. Never use it to bypass permission checks on an endpoint that accepts PAT authentication

### Step 6: Add Authorization Tests

**Goal:** Verify that granular PAT permissions are correctly enforced on endpoints.

Test files are usually located at `spec/requests/api/<resource>_spec.rb`. If you don't find them there, you may need to look around a bit more for the relevant spec files.

**What These Tests Do:**
These tests verify that:

- Legacy (non-granular) personal access tokens continue to grant access to the endpoint
- Legacy tokens are denied access when the boundary's top-level group enforces fine-grained tokens
- Users with the required permission granted in a granular PAT are allowed access
- Users without the required permission are denied access with a 403 Forbidden response and proper error message (`insufficient_granular_scope`)
- The authorization system correctly evaluates the granular scope against the endpoint's permission requirements
- The feature flag `granular_personal_access_tokens` is properly enforced (denies access when disabled)
- For `:project` and `:group` boundaries on public resources, the public-resource bypass mirrors a non-member request: a granular PAT without scope grants access to a GET endpoint exactly when a legacy non-member token does (which catches permissions missing from `public_anonymous.yml`), and never grants access through a non-GET endpoint

#### Add Shared Examples for Each Endpoint

For each endpoint, add the `'authorizing granular token permissions'` shared example. This is a reusable test helper that validates authorization behavior:

```ruby
it_behaves_like 'authorizing granular token permissions', :<permission_name> do
  let(:boundary_object) { <boundary_object> }
  let(:user) { <user> }
  let(:request) do
    <http_method> api("<endpoint_path>", personal_access_token: pat), params: <params_if_needed>
  end
end
```

The shared example accepts these keyword arguments after the permission name. They are keyword
arguments to `it_behaves_like` (before the `do`), not `let` definitions:

- `expected_success_status:` when the success response is not `:success`. Common values are
  `:created`, `:accepted`, `:no_content`, and `:redirect` (for download or file endpoints).
- `legacy_token_scopes:` when the endpoint requires legacy token scopes other than the default
  `%w[api]`.

```ruby
it_behaves_like 'authorizing granular token permissions', :create_release, expected_success_status: :created do
```

The "granting access" assertion expects a real success response, so supply valid `params` and make
sure any resource the request path references exists. Reuse the `let` definitions and setup of the
`describe` block that already tests the endpoint, and place the shared example inside that block.

#### Boundary Object Mapping

The `boundary_object` must match the `boundary_type`:

| Boundary Type | Boundary Object |
|---------------|-----------------|
| `:project` | `project` |
| `:group` | `group` |
| `:user` | `:user` |
| `:instance` | `:instance` |

**Important:** When the boundary object is a `:project` or `:group`, the `user` must be a member of that namespace (project or group) for the authorization to be granted. Always define `user`, even for `:user` and `:instance` boundaries, because the legacy token context creates an admin-mode token for that user.

### Step 7: Manual Validation

**Goal:** Manually test your implementation in a local environment to verify permissions work as expected before creating a merge request.

Use this if you want to test your endpoint and permissions in a Rails console before running the full test suite.

**Setup:**

In Rails console, create a granular PAT for a user and copy a URL to test the endpoint with the token:

```ruby
# Enable feature flag
Feature.enable(:granular_personal_access_tokens)

user = User.human.first

# Create granular token
token = PersonalAccessTokens::CreateService.new(
  current_user: user,
  target_user: user,
  organization_id: user.organization_id,
  params: { expires_at: 1.month.from_now, scopes: ['granular'], granular: true, name: 'gPAT' }
).execute[:personal_access_token]

# Get the appropriate boundary object (project, group, :user, or :instance)
project = user.projects.first
boundary = Authz::Boundary.for(project)

# Create a scope with the assignable permission being tested (replace :read_job with yours).
# Scopes store assignable permission names, which expand to raw permissions at request time.
scope = Authz::GranularScope.new(namespace: boundary.namespace, access: boundary.access, permissions: [:read_job])

# Add the scope to the token
Authz::GranularScopeService.new(token).add_granular_scopes(scope)

# Copy the API endpoint URL with the token (replace with your endpoint)
IO.popen('pbcopy', 'w') { |f| f.puts "curl \"http://#{Gitlab.host_with_port}/api/v4/projects/#{project.id}/jobs\" --request GET --header \"PRIVATE-TOKEN: #{token.token}\"" }
```

1. Paste the URL in another terminal. It should succeed.

### Step 8: Validate and regenerate documentation

**Goal:** Confirm all permission definitions, decorators, and tests are consistent, and update the generated reference documentation.

1. Regenerate the fine-grained token reference documentation:

   ```shell
   bundle exec rake gitlab:permissions:routes:compile_docs
   ```

   This updates `doc/auth/tokens/fine_grained_access_tokens_rest.md`. Do not edit that file by hand.

1. Run the permissions validation:

   ```shell
   bundle exec rake gitlab:permissions:validate
   ```

   The task also runs as a Lefthook pre-push hook. Among other checks, it fails when:

   - An endpoint has no `route_setting :authorization` decorator and no skip reason.
   - A permission in a decorator has no raw permission definition file.
   - A permission in a decorator is not part of any assignable permission.
   - The decorator's boundary types don't match the assignable permission's `boundaries`.
   - A skip reason is not defined in `lib/tasks/gitlab/permissions/routes/skip_reasons.rb`.
   - An endpoint's permission has no authorization test. Each endpoint declaration needs its own
     test per boundary type. Routes generated from a single declaration (for example, a shared
     concern mounted at both instance and project level) count as one endpoint.
   - The generated reference documentation is out of date.

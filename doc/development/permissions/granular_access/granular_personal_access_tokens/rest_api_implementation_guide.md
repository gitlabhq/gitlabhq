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

This guide walks you through adding granular PAT authorization to REST API endpoints. Before starting, review the [Permission Naming Conventions](../../conventions.md) documentation to understand the terminology used throughout.

**Note:** These steps cover REST API endpoints only. For GraphQL endpoint protection, refer to [GraphQL protection](graphql_granular_token_authorization.md).

### Workflow Overview

The implementation follows this flow:

1. **Step 1-2:** Plan - Identify endpoints and design permissions
1. **Step 3:** Create raw permissions (YAML files + generator)
1. **Step 4:** Bundle raw permissions into assignable permissions (YAML files)
1. **Step 5:** Add authorization decorators to endpoints (Ruby code)
1. **Step 6:** Write authorization tests (Ruby specs)
1. **Step 7:** Test locally (manual validation)

### Files Created by Each Step

Quick reference showing what you create in each step:

| Step | File Type | Location | Quantity | Example |
|------|-----------|----------|----------|---------|
| 2 | Planning document | (mental notes) | — | Permission names identified |
| 3 | Raw permission YAML | `config/authz/permissions/<resource>/<action>.yml` | 1 per permission | `config/authz/permissions/job/read.yml` |
| 3 | Raw permission resource metadata | `config/authz/permissions/<resource>/_metadata.yml` | 1 per resource | `config/authz/permissions/job/_metadata.yml` |
| 4 | Assignable permission YAML | `config/authz/permission_groups/assignable_permissions/<category>/<resource>/<action>.yml` | 1 per group | `config/authz/permission_groups/assignable_permissions/ci_cd/job/run.yml` |
| 4 (optional) | Category metadata | `config/authz/permission_groups/assignable_permissions/<category>/_metadata.yml` | 0 or 1 per category | `config/authz/permission_groups/assignable_permissions/ci_cd/_metadata.yml` |
| 4 | Resource metadata | `config/authz/permission_groups/assignable_permissions/<category>/<resource>/_metadata.yml` | 1 per resource | `config/authz/permission_groups/assignable_permissions/ci_cd/job/_metadata.yml` |
| 5 | Grape decorators | Modify `lib/api/<resource>.rb` | 1 per endpoint | Added `route_setting :authorization` |
| 6 | RSpec tests | Modify `spec/requests/api/<resource>_spec.rb` | 1 per endpoint | Added `it_behaves_like 'authorizing...'` |

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

**Note:** These endpoints are the basis for the raw permissions you'll create in the next step. Each unique operation (HTTP verb + route) typically needs its own permission.

### Step 2: Determine Permissions Needed

**Goal:** Define granular permissions following GitLab naming conventions.

For the naming conventions, see [Naming Permissions](../../conventions.md#naming-permissions) in the conventions documentation.

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

**Goal:** Create YAML definition files for each permission.

Generate a permission definition file using the Rails generator:

```shell
bundle exec rails generate authz:permission <permission_name>
```

This creates a YAML file at `config/authz/permissions/<resource>/<action>.yml`. The generator automatically parses the permission name to determine the resource and action directories.

#### Complete the YAML Definition

The generated file includes a template. Fill in all required fields:

```yaml
---
name: read_job
description: Grants the ability to read CI/CD jobs
```

**Required Fields:**

| Field | Description |
|-------|-------------|
| `name` | Permission name (auto-populated by generator) |
| `description` | Human-readable description of what the permission allows |

For additional details, see the [Permission Definition File](../../conventions.md#permission-definition-file) section in the conventions documentation.

#### Create Resource Metadata for Raw Permissions

For each resource directory, you must create a `_metadata.yml` file at `config/authz/permissions/<resource>/_metadata.yml`:

```yaml
---
feature_category: continuous_integration
name: "Job"
description: "Description of what permissions in this resource group do"
```

**Required Fields:**

- `feature_category` (required) - Must be a valid entry from `config/feature_categories.yml`. Look at existing endpoints in the API file for that resource to find the correct feature category. For example, CI/CD endpoints typically use `continuous_integration`, while package-related endpoints use `package_registry`.

**Optional Fields:**

- `name` - Overrides the titleized resource name for display
- `description` - Provides context about what permissions in this resource group grant

#### Permission Naming and Validation

The validation task (`bundle exec rake gitlab:permissions:validate`) enforces several constraints:

**Permission Name Format:**

For guidance on how to name permissions, see [Naming Permissions](../../conventions.md#naming-permissions) in the conventions documentation.

**Action Words:**

For a list of disallowed actions, see [Disallowed Actions](../../conventions.md#disallowed-actions) in the conventions documentation.

**File Structure:**

- Raw permissions must be at exactly: `config/authz/permissions/<resource>/<action>.yml`
- Assignable permissions must be at exactly: `config/authz/permission_groups/assignable_permissions/<category>/<resource>/<action>.yml`
- No extra directories allowed between the base path and the final filename

**Boundary Matching:**

- Each route's `boundary_type` must match at least one boundary in the assignable permission's `boundaries` field
- Example: If a route declares `boundary_type: :project`, the assignable permission must include `project` in its boundaries

All violations will be caught by running `bundle exec rake gitlab:permissions:validate`, which should pass before creating a merge request.

### Step 4: Assign Permissions to Assignable Permissions

**Goal:** Create assignable permissions that bundle related permissions for a simpler user experience.

Assignable permissions bundle one or more permissions that can be enabled for a granular PAT. They allow you to adjust the level of granularity presented to users, letting the product group decide whether to group permissions finely (e.g., read issue and read snippet permissions separately) or more broadly (e.g., all read work item permissions together). This maintains fine-grained control at the API endpoint level while providing a user-friendly experience in the UI.

#### Create the Assignable Permission File

Create a new YAML file manually at `config/authz/permission_groups/assignable_permissions/<category>/<resource>/<action>.yml`:

```yaml
---
name: run_job
description: Grants the ability to run jobs
permissions:
  - play_job
  - retry_job
boundaries:
  - group
  - project
```

#### Understanding the Directory Structure

The directory structure uses three levels: `<category>/<resource>/<action>.yml`

**When Do You Need Metadata Files?**

| File | When Required | Purpose |
|------|---------------|---------|
| Category `_metadata.yml` | Optional | Override folder name display (e.g., `ci_cd` → "CI/CD" instead of "Ci Cd") |
| Resource `_metadata.yml` | Required | Provide user-facing description of the resource. The `description` field is mandatory. |

Note: The assignable permission YAML file (at `<category>/<resource>/<action>.yml`) is always required and is not a metadata file—it's the main configuration file that defines the permission bundle.

**Category Level:** The `<category>` subfolder represents the name of the category displayed in the UI where assignable permissions are grouped. The folder name is titleized when displayed (e.g., `project_management` becomes "Project Management"). This category name is displayed when users create a granular PAT, helping them organize and find permissions by functional area.

Create a `_metadata.yml` file in the category folder **only if** titleization produces an incorrect display name. For example, acronyms or abbreviations that don't titleize well:

```yaml
---
name: "CI/CD"
```

**Examples of category-level metadata:**

- Folder: `project_management` → Without metadata: Displays as "Project Management"
- Folder: `ci_cd` → Without metadata: Displays as "Ci Cd" (incorrect)
- Folder: `ci_cd` → With `_metadata.yml` override: Displays as "CI/CD" (correct)

**Resource Level:** Create a `_metadata.yml` file at `config/authz/permission_groups/assignable_permissions/<category>/<resource>/_metadata.yml` to add metadata about the resource. The `description` field is mandatory:

```yaml
---
description: "Description of what permissions in this resource group do"
name: "SSH Key"
```

**Fields:**

- `description` (required) - Provides context about what permissions in this resource group grant. This description is displayed in the UI when users create a granular PAT, helping them understand what permissions they're assigning
- `name` (optional) - Overrides the titleized resource name for display. Use this for acronyms or special formatting where titleization won't work correctly (e.g., `name: "SSH Key"` instead of auto-titleized name)

The resource metadata file is required for every resource directory that contains assignable permissions. Validation will fail if any resource directory is missing a `_metadata.yml` file.

**Example in the UI:**

The following screenshot shows how category and resource metadata are displayed when a user creates a granular PAT:

![Granular PAT UI showing resource metadata](img/granular_pat_resource_metadata_ui_v18_10.png)

In this example:

- **CI/CD** - This is the category name, which comes from the folder name and can be overridden with category `_metadata.yml`
- **CI Config** - This is the resource name, which comes from the folder name and can be overridden with resource `_metadata.yml`
- The description below shows the `description` field from the resource `_metadata.yml` file

**Assignable Permission File Fields:**

| Field | Description |
|-------|-------------|
| `name` | Unique identifier for the assignable permission |
| `description` | Human-readable description of what the assignable permission grants |
| `permissions` | Array of raw permissions included in this assignable permission (must already exist from Step 3) |
| `boundaries` | List of organizational levels where the assignable permission applies |

#### Determining Boundaries

The `boundaries` field specifies which organizational levels support this assignable permission. Choose based on where the bundled raw permissions can be applied. Use the principle of least privilege—only include boundaries where the permissions actually apply.

**Boundary Types:**

- `instance` - Permissions applicable at the GitLab instance level (admin-only operations like viewing audit logs, managing system settings)
  - **Use sparingly** — typically only for admin-facing permissions

- `group` - Permissions applicable to groups and group-level resources (manage group members, group settings, group-owned projects)
  - Include this if your raw permissions work on group endpoints like `/groups/:id/...`

- `project` - Permissions applicable to projects and project-level resources (manage issues, create pipelines, update repository settings)
  - Include this if your raw permissions work on project endpoints like `/projects/:id/...`

- `user` - Permissions applicable to user-level resources (personal profile, personal settings, user-owned resources)
  - Include this if your raw permissions work on user endpoints like `/users/:id/...` or personal namespace operations

**Selecting Boundaries:**
Review the endpoint routes in your API file. If endpoints follow patterns like `/projects/:id/...`, include `project`. If endpoints follow `/groups/:id/...`, include `group`. Only include boundaries that your endpoints actually support.

#### Important Constraints

- Each raw permission included in the assignable permission **must already exist** (created in Step 3)
- Only raw permissions assigned to assignable permissions can be used to authorize API requests using granular PATs
- Use consistent naming across related assignable permissions

#### Validate Assignable Permissions

After creating or modifying assignable permissions, validate the file structure:

```shell
bundle exec rake gitlab:permissions:validate
```

This ensures your assignable permissions are properly formatted and reference valid raw permissions.

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
| `boundary_param` | Optional. The request parameter containing the boundary identifier. Defaults to `:id` for projects and `:id` or `:group_id` for groups |
| `boundaries` | Alternative to `boundary_type` for endpoints supporting multiple boundaries (see below) |
| `boundary` | Alternative to `boundary_type` for endpoints where the boundary cannot be determined through standard parameter lookup. A callable object (proc, lambda, or method) that returns the boundary object |
| `skip_granular_token_authorization` | Optional. When set to `true`, allows granular PATs to access the endpoint without requiring specific permissions (see below) |

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

- The system evaluates boundaries in priority order: `project` > `group` > `user` > `instance`
- The first boundary that can be resolved (based on available parameters) is used for authorization
- Each boundary in the array requires a `boundary_type` key and optionally a `boundary_param` key to specify which request parameter contains the boundary identifier

#### Skipping Granular Token Authorization

Some endpoints don't require authentication and are publicly accessible, or do not implement token authentication. Since token authentication is skipped for these endpoints, defining granular permissions doesn't make sense. However, to maintain coverage tracking for all endpoints, use the `skip_granular_token_authorization` option:

```ruby
route_setting :authorization, skip_granular_token_authorization: true
get 'public-endpoint' do
  # endpoint implementation
end
```

**When to use `skip_granular_token_authorization`:**

- Public endpoints that don't require authentication
- Endpoints that authenticate by other means than personal access tokens
- Discovery or metadata endpoints that are accessible without authentication
- Endpoints where authentication is optional and the response is the same regardless

Adding this decorator ensures that all endpoints are explicitly covered by the authorization system, even those that don't require permissions.

**Important Notes:**

- Add the decorator to **every endpoint** individually, even if multiple endpoints use the same permission
- The decorator goes **immediately before** the HTTP method definition (`get`, `post`, `put`, `delete`)
- Use the exact permission name (symbol) defined in your YAML files
- Use `boundary_type` or `boundary` for single-boundary endpoints; use `boundaries` array for multi-boundary endpoints
- Use `skip_granular_token_authorization: true` sparingly and only for endpoints that truly don't require permission checks

### Step 6: Add Authorization Tests

**Goal:** Verify that granular PAT permissions are correctly enforced on endpoints.

Test files are usually located at `spec/requests/api/<resource>_spec.rb`. If you don't find them there, you may need to look around a bit more for the relevant spec files.

**What These Tests Do:**
These tests verify that:

- Legacy (non-granular) personal access tokens continue to grant access to the endpoint
- Users with the required permission granted in a granular PAT are allowed access
- Users without the required permission are denied access with a 403 Forbidden response and proper error message (`insufficient_granular_scope`)
- The authorization system correctly evaluates the granular scope against the endpoint's permission requirements
- The feature flag `granular_personal_access_tokens` is properly enforced (denies access when disabled)

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

#### Boundary Object Mapping

The `boundary_object` must match the `boundary_type`:

| Boundary Type | Boundary Object |
|---------------|-----------------|
| `:project` | `project` |
| `:group` | `group` |
| `:user` | `:user` |
| `:instance` | `:instance` |

**Important:** When the boundary object is a `:project` or `:group`, the `user` must be a member of that namespace (project or group) for the authorization to be granted.

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

# Create scope with the permission being tested (replace :read_job with your permission)
scope = Authz::GranularScope.new(namespace: boundary.namespace, access: boundary.access, permissions: [:read_job])

# Add the scope to the token
Authz::GranularScopeService.new(token).add_granular_scopes(scope)

# Copy the API endpoint URL with the token (replace with your endpoint)
IO.popen('pbcopy', 'w') { |f| f.puts "curl \"http://#{Gitlab.host_with_port}/api/v4/projects/#{project.id}/jobs\" --request GET --header \"PRIVATE-TOKEN: #{token.token}\"" }
```

1. Paste the URL in another terminal. It should succeed.

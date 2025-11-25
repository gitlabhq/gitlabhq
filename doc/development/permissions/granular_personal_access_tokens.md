---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Granular Personal Access Tokens
---

Granular PATs allow fine-grained access control by requiring specific permissions for each API endpoint, adhering to the principle of least privilege. This documentation is designed for community contributors and GitLab developers who want to make API endpoints compliant with granular PATs.

## Background

Granular PATs enable users to create personal access tokens with specific, limited permissions rather than broad access. Each API endpoint is protected by explicit permissions that must be granted to the token. This improves security by ensuring tokens only have access to the resources they explicitly need.

## Prerequisites

Before starting, ensure you:

- Have a local GitLab development environment set up
- Are familiar with GitLab API structure (`lib/api/`)
- Understand Ruby on Rails and RSpec testing
- Have read the [Permission Naming Conventions](conventions.md) documentation

## Step-by-Step Implementation Guide

### Step 1: Identify API Endpoints for the Resource

**Goal:** Find all REST API endpoints for the resource you're working on.

1. Go to the API file for your resource:

```plaintext
   lib/api/<resource_name>.rb
```

   Example: For jobs, open `lib/api/jobs.rb`

1. Review all endpoints defined in the file. Look for HTTP methods and routes:

```ruby
   get ':id/jobs'
   get ':id/jobs/:job_id'
   post ':id/jobs/:job_id/cancel'
   post ':id/jobs/:job_id/retry'
   delete ':id/jobs/:job_id/artifacts'
```

### Step 2: Determine Permissions Needed

**Goal:** Define granular permissions following GitLab naming conventions.

For guidance on permission granularity and preferred actions, see the [Naming Permissions](conventions.md#naming-permissions) section in the conventions documentation.

#### Permission Naming Pattern

Follow the pattern: `action_resource(_subresource)`
**Use singular** instead of plural for the resource and subresource. Example: `read_job` (instead of `read_jobs` regardless of which boundary it applies to) and `create_pipeline_schedule_variable`.

**Examples:**

| Endpoint | HTTP Method | Permission Name |
|----------|-------------|-----------------|
| `GET /projects/:id/jobs` | GET | `read_job` |
| `GET /projects/:id/jobs/:job_id` | GET | `read_job` |
| `POST /projects/:id/jobs/:job_id/cancel` | POST | `cancel_job` |
| `POST /projects/:id/jobs/:job_id/retry` | POST | `retry_job` |
| `DELETE /projects/:id/jobs/:job_id/artifacts` | DELETE | `delete_job_artifact` |
| `POST /projects/:id/pipeline_schedules/:schedule_id/variables` | POST | `create_pipeline_schedule_variable` |
| `DELETE /projects/:id/pipeline_schedules/:schedule_id/variables/:key` | DELETE | `delete_pipeline_schedule_variable` |

#### Common Patterns

- **List and Show operations**: Use a single `read_resource` permission for both
  - `GET /projects/:id/jobs` → `read_job`
  - `GET /projects/:id/jobs/:job_id` → `read_job`

- **Nested resources**: Include the parent resource in the permission name
  - `POST /projects/:id/pipeline_schedules/:id/variables` → `create_pipeline_schedule_variable`

- **Special actions**: Create specific permissions for unique operations
  - Cancel, retry, download, trigger, etc. each get their own permission

- **Attribute updates**: Do not create separate permissions for individual attributes
  - `update_issue` covers updating title, description, assignees, etc.
  - Do not create `update_issue_description`, `update_issue_title`

### Step 3: Generate Permission Definition Files

**Goal:** Create YAML definition files for each new permission.

For details on generating permission definition files, see the [Permission Definition File](conventions.md#permission-definition-file) section in the conventions documentation.

#### Complete the YAML Definition

The generator creates a template. Fill in all required fields:

```yaml
---
name: read_job
description: Grants the ability to read CI/CD jobs
feature_category: continuous_integration
available_for_tokens: true
boundaries:
  - group
  - project
```

**Required Fields:**

| Field | Description | How to Find |
|-------|-------------|-------------|
| `name` | Permission name (auto-populated) | Matches the permission name |
| `description` | Human-readable description of what the permission allows | Describe the capability granted |
| `feature_category` | GitLab feature category | Found in `lib/api/<resource>.rb` - search for `feature_category` |
| `available_for_tokens` | Indicates if this permission can be assigned to a granular token | Set to `true` for granular PAT permissions |
| `boundaries` | List of organizational levels where the permission applies | Determined by the route pattern - `project` for `/projects/:id/...`, `group` for `/groups/:id/...`, `user` for `/users/:id/...`, `instance` for no prefix |

### Step 4: Define Permission Groups (Optional)

**Goal:** Group related permissions together for easier token configuration.

Permission groups allow you to bundle multiple related permissions under a single logical group. This is useful when you want to maintain granularity at the API endpoint level while providing a simpler, more user-friendly experience in the UI. Instead of presenting users with many individual permissions, you can offer broader permission groups that grant multiple related capabilities at once.

You can define permission groups in `config/authz/permission_groups/<resource>/<action>.yml`. The following example shows a YAML file for the `config/authz/permission_groups/job/run.yml` permission group:

```yaml
---
name: run_job
description: Grants the ability to run jobs
permissions:
  - play_job
  - retry_job
available_for_tokens: true
boundaries:
  - group
  - project
```

Each permission included in the group should exist as an individual permission, with a `false` value for the `available_for_tokens` key.

### Step 5: Add Authorization Decorators to API Endpoints

For each endpoint, add the `route_setting :authorization` decorator immediately before the route definition:

```ruby
route_setting :authorization, permissions: :read_job, boundary_type: :project
get ':id/jobs' do
  # endpoint implementation
end
```

**Important Notes:**

- Add the decorator to **every endpoint** individually, even if multiple endpoints use the same permission
- The decorator goes **immediately before** the HTTP method definition (`get`, `post`, `put`, `delete`)
- Use the exact permission name (symbol) defined in your YAML files

### Step 6: Add Test Coverage

Test files are usually located at `spec/requests/api/<resource>_spec.rb`. If you don't find them there, you may need to look around a bit more for the relevant spec files.

#### Add Shared Examples for Each Endpoint

For each endpoint, add the `'authorizing granular token permissions'` shared example:

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
| `:user` | `user` |
| `:instance` | `nil` or not specified |

### Step 7: Create Merge Request

Submit your changes for review following GitLab contribution process.

#### MR Scope

- Complete **one resource per MR** (Example - all Jobs endpoints in one MR)
- Do not mix multiple resources in a single MR

#### MR Description Template

Include the following in your MR description:

```markdown
## Summary

This MR enables granular Personal Access Token (PAT) permissions for [Resource Name] REST API endpoints.

## Endpoints Modified

- `GET /projects/:id/jobs` - `read_job`
- `GET /projects/:id/jobs/:job_id` - `read_job`
- `POST /projects/:id/jobs/:job_id/cancel` - `cancel_job`
- `POST /projects/:id/jobs/:job_id/retry` - `retry_job`
- `DELETE /projects/:id/jobs/:job_id/artifacts` - `delete_job_artifact`

## Permissions Created

- `read_job` - Grants the ability to read CI/CD jobs
- `cancel_job` - Grants the ability to cancel running or pending jobs
- `retry_job` - Grants the ability to retry failed jobs
- `delete_job_artifact` - Grants the ability to delete job artifacts

## Testing

- Added authorization tests using shared examples for all endpoints

## How to set up and validate locally

1. In Rails console, create a granular PAT for a user and copy a URL to test the endpoint with the token:

```ruby
# Enable feature flag
Feature.enable(:authorize_granular_pats)

user = User.first

# Create granular token
token = PersonalAccessTokens::CreateService.new(
  current_user: user,
  target_user: user,
  organization_id: user.organization_id,
  params: { expires_at: 1.month.from_now, scopes: ['granular'], granular: true, name: 'gPAT' }
).execute[:personal_access_token]

# Get the appropriate boundary object (project, group, or user)
project = user.projects.first

# Create scope with the permission being tested (replace :read_job with your permission)
scope = Authz::GranularScope.new(namespace: project.project_namespace, permissions: [:read_job])

Authz::GranularScopeService.new(token).add_granular_scopes(scope)

# Copy the API endpoint URL with the token (replace with your endpoint)
IO.popen('pbcopy', 'w') { |f| f.puts "curl \"http://#{Gitlab.host_with_port}/api/v4/projects/#{project.id}/jobs\" --request GET --header \"PRIVATE-TOKEN: #{token.token}\"" }
```

1. Paste the URL in another terminal. It should succeed.

## Related Issues

Closes #[issue_number]

### Checklist Before Submitting

- [ ] All permission YAML files are complete with description and feature_category
- [ ] Authorization decorators added to all endpoints
- [ ] Test coverage added for all endpoints using shared examples
- [ ] Tests pass locally: `bundle exec rspec spec/requests/api/<resource>_spec.rb`
- [ ] MR description lists all modified endpoints
- [ ] MR is linked to the related issue

### Reviewers

Tag the authorization team _@GitLab-org/software-supply-chain-security/authorization/approvers_ for review.

## Edge Cases and Special Considerations

### Endpoints Requiring Multiple Permissions

**Status:** TBD (To Be Determined)

This scenario is still under discussion by the Authorization team. If you encounter an endpoint that logically requires multiple permissions (Example: read project and read jobs), you should:

1. Document the use case in your MR description
1. Tag the Authorization team for guidance
1. Wait for team input before proceeding

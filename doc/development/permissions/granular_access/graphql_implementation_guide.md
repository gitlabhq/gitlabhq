---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: GraphQL implementation guide
---

To reduce the security impact of compromised Personal Access Tokens (PATs), granular or fine-grained PATs allow users to create tokens with fine-grained permissions limited to specific organizational boundaries (groups, projects, user, or instance-level). This enables users to follow the principle of least privilege by granting tokens only the permissions they need.

Granular PATs allow fine-grained access control through granular scopes that consist of a boundary and specific resource permissions. When authenticating GraphQL requests with a granular PAT, GitLab validates that the token's permissions include access to the requested resource at the specified boundary level.

This documentation is designed for community contributors and GitLab developers who want to make GraphQL queries and mutations compliant with granular PAT authorization.

## Step-by-Step Implementation Guide

This guide walks you through adding granular PAT authorization to GraphQL types and mutations. Before starting, review the [Permission Naming Conventions](../conventions.md) documentation to understand the terminology used throughout.

> [!note]
> These steps cover GraphQL types and mutations only. For REST API endpoint protection, refer to the [REST API implementation guide](rest_api_implementation_guide.md).

For a detailed explanation of how the authorization system works internally, see the [GraphQL architecture documentation](graphql_architecture.md).

### Workflow Overview

The implementation follows this flow:

1. **Step 1-2:** Plan - Identify types/mutations and design permissions
1. **Step 3:** Create raw permissions (YAML files)
1. **Step 4:** Bundle raw permissions into assignable permissions (YAML files)
1. **Step 5:** Add authorization directives to types/mutations (Ruby code)
1. **Step 6:** Write authorization tests (Ruby specs)
1. **Step 7:** Test locally (manual validation)

### Step 1: Identify GraphQL Types and Mutations to Protect

**Goal:** Find all GraphQL types and mutations for the resource you're working on.

1. Locate the GraphQL type for your resource in `app/graphql/types/`.

   Example: For the issue resource, open `app/graphql/types/issue_type.rb`

1. Locate any related mutations in `app/graphql/mutations/`.

   Example: For issues, check `app/graphql/mutations/issues/`

1. Identify which types and mutations need authorization:

   - **Object types** that represent resources users access (e.g., `IssueType`, `ProjectType`)
   - **Mutations** that create, update, or delete resources (e.g., `Mutations::Issues::Create`)
   - **Query fields** that return resources directly (e.g., `field :project` on `QueryType`)

1. Check if any types or mutations already have `authorize_granular_token` directives. You'll need to add directives to types/mutations that don't have them.

### Step 2: Determine Permissions Needed

**Goal:** Define granular permissions following GitLab naming conventions.

For the naming conventions, see [Naming Permissions](../conventions.md#naming-permissions) in the conventions documentation.

#### Determining the Permission Name for Types and Mutations

When implementing granular PAT authorization, name permissions based on what the type **represents** or what the mutation **does**, not the GraphQL schema structure.

**Examples:**

- Type `IssueType` → represents reading issues → permission name is `read_issue`
- Mutation `Mutations::Issues::Create` → creates an issue → permission name is `create_issue`
- Type `ProjectType` → represents reading project data → permission name is `read_project`

#### Common Patterns

- **Object types**: Use a `read_resource` permission that covers all fields on the type
  - `IssueType` → `read_issue`
  - `ProjectType` → `read_project`
- **Create mutations**: Use `create_resource`
  - `Mutations::Issues::Create` → `create_issue`
- **Update mutations**: Use `update_resource`
  - `Mutations::Issues::Update` → `update_issue`
- **Delete mutations**: Use `delete_resource`
  - `Mutations::Issues::Destroy` → `delete_issue`
- **Special action mutations**: Create specific permissions for unique operations
  - Move, archive, transfer, etc. each get their own permission

### Step 3: Create Permission Definition Files

**Goal:** Create YAML definition files for each permission, if it doesn't exist yet.

Follow the instructions in the [Permission Definition File](permission_definitions.md#permission-definition-file) section to create raw permission YAML files using the `bin/permission` command. This step is the same for both REST API and GraphQL implementations.

### Step 4: Create Assignable Permissions

**Goal:** Bundle raw permissions into assignable permissions for a simpler user experience.

Follow the instructions in the [Assignable Permissions](assignable_permissions.md) section to create assignable permission YAML files. This step is the same for both REST API and GraphQL implementations.

### Step 5: Add Authorization Directives to Types and Mutations

**Goal:** Add granular PAT authorization directives to GraphQL types and mutations.

Use the `authorize_granular_token` method to declare permissions on types and mutations. This method is available on all GraphQL types (via `Types::BaseObject`) and mutations (via `Mutations::BaseMutation`).

**Method Signature:**

```ruby
authorize_granular_token(permissions:, boundary_type:, boundary: nil, boundary_argument: nil)
```

**Parameters:**

| Parameter | Description |
|-----------|-------------|
| `permissions` | **(Required)** Symbol representing the required permission (e.g., `:read_issue`). Can also be an array of permissions. Must be a valid permission from `Authz::PermissionGroups::Assignable.all_permissions` — validated by the `gitlab:permissions:validate` Rake task. |
| `boundary_type` | **(Required)** Symbol declaring the type of authorization boundary (`:project`, `:group`, `:user`, `:instance`). Validated against the assignable permission boundaries by the `gitlab:permissions:validate` Rake task. |
| `boundary` | Symbol representing the method to call on the resolved object to extract the boundary (e.g., `:project`). Use `:user` or `:instance` for standalone resources. |
| `boundary_argument` | Symbol representing the argument name containing the boundary path (e.g., `:project_path`). |

**For object types:**

```ruby
class IssueType < BaseObject
  authorize_granular_token permissions: :read_issue, boundary: :project, boundary_type: :project
end
```

**For mutations:**

```ruby
module Mutations
  module Issues
    class Create < BaseMutation
      authorize_granular_token permissions: :create_issue, boundary_argument: :project_path, boundary_type: :project
    end
  end
end
```

#### When `boundary` applies

- Fields **on** the type (e.g., `issue.title` when `IssueType` has directive)
- Query fields with `:id` argument returning the type (enables ID fallback)
- Standalone resources using `boundary: :user` or `boundary: :instance`
- **Does not apply to** query fields **without** `:id` argument returning the type (object not available, raises ArgumentError)

##### When `boundary_argument` applies

- Root mutations
- Root query fields
- Any field that receives boundary as an argument
- Fields returning types with `boundary_argument` directive

##### Standalone Boundaries

Use `boundary: :user` or `boundary: :instance` for resources that don't belong to a specific project or group:

```ruby
class UserSettingType < BaseObject
  authorize_granular_token permissions: :read_user_settings, boundary: :user, boundary_type: :user
end
```

#### Choosing Between `boundary` and `boundary_argument`

| Use `boundary` when... | Use `boundary_argument` when... |
|------------------------|-------------------------------|
| The type has a method to get the boundary (e.g., `issue.project`) | The boundary is passed as a field argument (e.g., `projectPath`) |
| Protecting an object type's fields | Protecting a mutation |
| Protecting a query field with `:id` argument | Protecting a query field with a path argument |

### Step 6: Add Authorization Tests

**Goal:** Verify that granular PAT permissions are correctly enforced on GraphQL types and mutations.

#### For Queries

Add the `'authorizing granular token permissions for GraphQL'` shared example:

```ruby
it_behaves_like 'authorizing granular token permissions for GraphQL', :<permission_name> do
  let(:user) { current_user }
  let(:boundary_object) { <boundary_object> }
  let(:request) { post_graphql(query, token: { personal_access_token: pat }) }
end
```

**Example:**

```ruby
it_behaves_like 'authorizing granular token permissions for GraphQL', :read_issue do
  let(:user) { current_user }
  let(:boundary_object) { project }
  let(:request) { post_graphql(query, token: { personal_access_token: pat }) }
end
```

#### For Mutations

```ruby
it_behaves_like 'authorizing granular token permissions for GraphQL', :<permission_name> do
  let(:user) { current_user }
  let(:boundary_object) { <boundary_object> }
  let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
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

**What These Tests Verify:**

- Legacy (non-granular) personal access tokens continue to grant access
- Users with the required permission granted in a granular PAT are allowed access
- Users without the required permission are denied access with a proper error message
- The authorization system correctly evaluates the granular scope against the type/mutation's permission requirements
- The feature flag `granular_personal_access_tokens` is properly enforced (denies access when disabled)

### Step 7: Manual Validation

**Goal:** Manually test your implementation in a local environment to verify permissions work as expected before creating a merge request.

**Setup:**

In Rails console, create a granular PAT for a user:

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

# Create scope with the assignable permissions being tested
scope = Authz::GranularScope.new(namespace: boundary.namespace, access: boundary.access, permissions: [:read_work_item, :write_work_item])

# Add the scope to the token
Authz::GranularScopeService.new(token).add_granular_scopes(scope)

# Copy a curl command for testing a GraphQL query
query = '{ project(fullPath: \"' + project.full_path + '\") { issues { nodes { title } } } }'
IO.popen('pbcopy', 'w') { |f| f.puts "curl \"http://#{Gitlab.host_with_port}/api/graphql\" --request POST --header \"PRIVATE-TOKEN: #{token.token}\" --header \"Content-Type: application/json\" --data '{\"query\": \"#{query}\"}'" }
```

1. Paste the command in another terminal. It should succeed.

## See Also

- [GraphQL architecture documentation](graphql_architecture.md): Detailed explanation of how the authorization system works internally
- [Assignable permissions](assignable_permissions.md): How to create assignable permission files
- [Permission naming conventions](../conventions.md): Naming guidelines for permissions
- [REST API implementation guide](rest_api_implementation_guide.md): Adding granular PAT authorization to REST API endpoints
- [Granular Personal Access Tokens Documentation](_index.md)

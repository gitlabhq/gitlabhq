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
1. **Step 8:** Validate and regenerate documentation (Rake tasks)

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

Follow the instructions in the [Assignable Permissions](assignable_permissions.md) documentation to create or update assignable permission YAML files. This step is the same for both REST API and GraphQL implementations.

### Step 5: Add Authorization Directives to Types and Mutations

**Goal:** Add granular PAT authorization directives to GraphQL types and mutations.

Use the `authorize_granular_token` method to declare permissions on types and mutations. This method is available on all GraphQL types (via `Types::BaseObject`), mutations (via `Mutations::BaseMutation`), and resolvers (via `Resolvers::BaseResolver`).

**Method Signature:**

```ruby
authorize_granular_token(permissions:, boundary_type: nil, boundary: nil, boundary_argument: nil, boundaries: nil, skip_reason: nil)
```

**Parameters:**

| Parameter | Description |
|-----------|-------------|
| `permissions` | **(Required)** Symbol representing the required permission (for example, `:read_issue`). Can also be an array of permissions. Must be a valid permission from `Authz::PermissionGroups::Assignable.all_permissions`. The `gitlab:permissions:validate` Rake task validates this. |
| `boundary_type` | Symbol declaring the type of authorization boundary (`:project`, `:group`, `:user`, `:instance`). Required when not using `boundaries:`. Validated against the assignable permission boundaries by the `gitlab:permissions:validate` Rake task. |
| `boundary` | Symbol representing the method to call on the resolved object to extract the boundary (for example, `:project`). Use `:itself` when the resolved object is the Project or Group itself (for example, on `ProjectType` and `GroupType`). Use `:user` or `:instance` for standalone resources. |
| `boundary_argument` | Symbol representing the argument name containing the boundary path (for example, `:project_path`). |
| `boundaries` | Array of boundary hashes for resources that support multiple boundary types. Each hash requires a `boundary_type` key and can include `boundary` or `boundary_argument`. For more details, see [Multiple boundaries](#multiple-boundaries). |
| `traversal` | Set to `true` on a per-field directive (passed through `granular_scope_directive`) for entry-point fields. Passing it to a type-level `authorize_granular_token` raises an `ArgumentError`. For more details, see [Entry-point fields](#entry-point-fields). Not currently enforced. |
| `skip_reason` | Symbol declaring that a type intentionally opts out of granular-token authorization. Use instead of `permissions:` and a boundary, not alongside them. For more details, see [Skip authorization with `skip_reason`](#skip-authorization-with-skip_reason). |

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

When the argument resolves to a record that is not itself a Project or Group, combine `boundary_argument` with `boundary`.
The argument locates the record, and `boundary` reaches the Project or Group from it:

```ruby
module Mutations
  module Notes
    module Create
      class Base < Mutations::Notes::Base
        authorize_granular_token permissions: :create_note,
          boundaries: [
            { boundary_argument: :noteable_id, boundary: :resource_parent, boundary_type: :project },
            { boundary_argument: :noteable_id, boundary: :resource_parent, boundary_type: :group }
          ]
      end
    end
  end
end
```

For the argument `noteable_id: "gid://gitlab/Issue/1"`, the extractor locates the issue, then calls `issue.resource_parent` to reach the boundary.

**For root query fields:**

Root query fields have no parent object, so the boundary is read from the field arguments with `boundary_argument`.
Declare the directive on the field's resolver.
Directives declared on a resolver are applied to the fields that mount it:

```ruby
module Resolvers
  module Ai
    class ToolRulesResolver < BaseResolver
      authorize_granular_token permissions: :read_ai_tool_rule, boundary_argument: :full_path, boundary_type: :group

      argument :full_path, GraphQL::Types::ID, required: true
    end
  end
end
```

When the token lacks the permission, the field resolves to `null`, matching how type-level authorization redacts objects.
For the full implementation and its authorization test, see
`ee/app/graphql/resolvers/ai/tool_rules_resolver.rb` and
`ee/spec/requests/api/graphql/ai/tool_rules_spec.rb`.

#### When `boundary` applies

- Fields on a resolved object (for example, `issue.title` when `IssueType` declares the directive).
- Types where the resolved object is the boundary itself (use `boundary: :itself`).
- Standalone resources using `boundary_type: :user` or `boundary_type: :instance`.

Use `boundary_argument` instead when the object is not yet resolved.

#### When `boundary_argument` applies

- Root mutations
- Root query fields that receive a path or GlobalID argument
- Any field that receives the boundary as an argument

#### Standalone boundaries

Use `boundary_type: :user` or `boundary_type: :instance` for resources that don't belong to a specific project or group. For these boundary types, the `boundary_type` alone determines the boundary. By convention, set `boundary:` to the same value:

```ruby
module Mutations
  module Todos
    class SnoozeMany < BaseMany
      authorize_granular_token permissions: :update_todo, boundary: :user, boundary_type: :user
    end
  end
end
```

#### Multiple boundaries

A resource that can belong to different boundary types declares each boundary with `boundaries:`.
`Ci::RunnerType` does this because a runner can belong to a project, belong to a group, or be instance-wide:

```ruby
class RunnerType < BaseObject
  authorize_granular_token(
    permissions: :read_runner,
    boundaries: [
      { boundary: :owner, boundary_type: :project },
      { boundary: :owner, boundary_type: :group },
      { boundary: :instance, boundary_type: :instance }
    ]
  )
end
```

A concrete boundary (project or group) is preferred when one resolves.
A directive whose resolved object does not match its declared `boundary_type` is skipped.
For an instance runner, `runner.owner` returns a `User`, so neither the project nor the group
directive matches, and the standalone `instance` boundary applies.
For more details, see [Multiple boundaries](graphql_architecture.md#multiple-boundaries).

#### Entry-point fields

> [!note]
> `traversal` is declared on the directive but is not currently enforced by `GranularScopeAuthorization`.
> A field marked `traversal: true` enforces the listed permissions like any other field.
> Enforcement is pending reimplementation. `Query.group` and `Query.project` do not currently
> declare the directive, and fields without granular-token directives do not perform granular
> checks themselves.

Top-level fields that resolve a boundary from a path argument, such as
`Query.group(fullPath:)` and `Query.project(fullPath:)`, do not expose data
themselves. Downstream fields enforce the actual permissions. Use
`traversal: true` on the directive so the entry point requires only that the
token is scoped to the boundary, not the listed permission.

```ruby
field :group, Types::GroupType,
  null: true,
  resolver: Resolvers::GroupResolver,
  description: "Find a group.",
  directives: granular_scope_directive(
    permissions: :read_group, boundary_argument: :full_path, boundary_type: :group,
    traversal: true
  )
```

Without `traversal: true` on such a directive, a token scoped to a child
resource (for example, `read_member`) cannot reach the parent in GraphQL, even
though the equivalent REST endpoint allows it. With `traversal: true`, the
token reaches the parent and only the downstream fields the user queries
enforce specific permissions.

The `permissions:` argument is still required because it documents the boundary
the entry point operates on, even though the field itself does not enforce it.

`traversal: true` only applies to `project` and `group` boundary types. For all
other boundary types, the listed permissions are enforced as normal.

#### Traversal between authorized types

When a field on an authorized type returns another type that also declares
`authorize_granular_token`, both directives are enforced.
`GranularScopeAuthorization` evaluates each type's and field's own directives
independently, so plan permissions assuming the token needs the owner type's
permissions as well as the child type's.

For example, `GroupType.groupMembers` returns `GroupMemberType`, and both types
declare granular-token directives. A token needs `read_group` to resolve fields
on the group and `read_member` to resolve fields on its members:

```graphql
query {
  group(fullPath: "gitlab-org") {
    groupMembers {
      nodes { id }
    }
  }
}
```

An automatic skip of the owner type's directive on traversal fields, so that a
token with only `read_member` could reach members through the group, was
previously implemented and is pending reimplementation. Do not rely on it.

#### Skip authorization with `skip_reason`

Some object types intentionally do not declare their own permissions. For these
types, declare a skip with `skip_reason:` to record why authorization is omitted.
The value names the reason, which documents the decision and lets the validator
distinguish an intentional skip from a type that is missing authorization.

```ruby
class VulnerabilityIdentifierType < BaseObject
  authorize_granular_token skip_reason: :parent_authorizes
end
```

The valid reasons and their meanings are defined in `lib/tasks/gitlab/permissions/graphql/skip_reasons.rb`.

The `gitlab:permissions:validate` Rake task requires every object type
to declare either a directive or a skip. Types that predate this requirement are
listed in `config/authz/graphql/authorization_todo.txt`. Do not add new entries to
that file. You cannot combine `skip_reason:` with `permissions:` or a boundary
argument.

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

#### For types that skip authorization

When a type declares `skip_reason: :parent_authorizes`, verify that its data is returned when the
parent type is authorized, and withheld when it is not. Set `skipped_data_path` to the GraphQL
response path of the skipped type's data:

```ruby
it_behaves_like 'authorizing granular token permissions for GraphQL with a skipped child type', :read_vulnerability do
  let(:user) { current_user }
  let(:boundary_object) { project }
  let(:request) { post_graphql(query, current_user: user, token: { personal_access_token: pat }) }
  let(:skipped_data_path) { %i[vulnerability identifiers] }
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
- Legacy tokens are denied access when the boundary's top-level group enforces fine-grained tokens
- Users with the required permission granted in a granular PAT are allowed access
- Users without the required permission are denied access. Unauthorized queries return `null` data with a `200` response, while unauthorized mutations return a top-level GraphQL error
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

# Create a scope with the assignable permissions being tested.
# Scopes store assignable permission names, which expand to raw permissions at request time.
# The example query below resolves fields on both ProjectType (raw permission read_project,
# part of the read_project assignable permission) and IssueType (raw permission read_issue,
# part of the read_work_item assignable permission), so the scope needs both.
scope = Authz::GranularScope.new(namespace: boundary.namespace, access: boundary.access, permissions: [:read_project, :read_work_item])

# Add the scope to the token
Authz::GranularScopeService.new(token).add_granular_scopes(scope)

# Copy a curl command for testing a GraphQL query
query = '{ project(fullPath: \"' + project.full_path + '\") { issues { nodes { title } } } }'
IO.popen('pbcopy', 'w') { |f| f.puts "curl \"http://#{Gitlab.host_with_port}/api/graphql\" --request POST --header \"PRIVATE-TOKEN: #{token.token}\" --header \"Content-Type: application/json\" --data '{\"query\": \"#{query}\"}'" }
```

1. Paste the command in another terminal. It should succeed.

### Step 8: Validate and regenerate documentation

**Goal:** Confirm all permission definitions and directives are consistent, and update the generated reference documentation.

1. Regenerate the fine-grained token reference documentation:

   ```shell
   bundle exec rake gitlab:permissions:graphql:compile_docs
   ```

   This updates `doc/auth/tokens/fine_grained_access_tokens_graphql.md`. Do not edit that file by hand.

1. Run the permissions validation:

   ```shell
   bundle exec rake gitlab:permissions:validate
   ```

   The task also runs as a Lefthook pre-push hook. Among other checks, it fails when:

   - An object type or mutation has neither a granular-token directive nor a `skip_reason:`,
     unless it is grandfathered in `config/authz/graphql/authorization_todo.txt`.
   - A permission in a directive is not part of any assignable permission.
   - The directive's `boundary_type` does not match the assignable permission's `boundaries`.
   - A `skip_reason:` is not defined in `lib/tasks/gitlab/permissions/graphql/skip_reasons.rb`.
   - A directive declares both `skip_reason:` and `permissions:`.
   - A permission in a directive has no authorization test. Each type, mutation, or field declaring
     the permission needs its own test per boundary type. This is strictly enforced with no
     grandfathered exceptions, so add the test in the same merge request as the declaration.
   - The generated reference documentation is out of date.

## See Also

- [GraphQL architecture documentation](graphql_architecture.md): Detailed explanation of how the authorization system works internally
- [Assignable permissions](assignable_permissions.md): How to create assignable permission files
- [Permission naming conventions](../conventions.md): Naming guidelines for permissions
- [REST API implementation guide](rest_api_implementation_guide.md): Adding granular PAT authorization to REST API endpoints
- [Granular Personal Access Tokens Documentation](_index.md)

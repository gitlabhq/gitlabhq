---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: GraphQL Granular Token Authorization
---

This document explains how the `GranularTokenAuthorization` field extension works to enforce granular Personal Access Token (PAT) permissions on GraphQL queries and mutations.

## Overview

The granular token authorization system adds fine-grained permission checks to GraphQL fields based on directives applied to types, fields, and mutations. It ensures that granular PATs can only access resources they have explicit permissions for within specific project or group boundaries.

**Feature Flag**: This feature requires both the `granular_personal_access_tokens` and the `granular_personal_access_tokens_for_graphql` feature flags to be enabled for the token's user. When either one is disabled, granular PATs will not work for GraphQL requests.

## Architecture Components

### 1. Field Extension

- **Location**: `lib/gitlab/graphql/authz/granular_token_authorization.rb`
- **Purpose**: Intercepts field resolution to perform authorization checks
- **Applied to**: All GraphQL fields via `Types::BaseField`

### 2. Directive

- **Location**: `app/graphql/directives/authz/granular_scope.rb`
- **Purpose**: Declares required permissions and boundary extraction strategy
- **Arguments**:
  - `permissions`: Array of required permission strings (e.g., `['READ_ISSUE']`)
  - `boundary`: Method name to extract boundary from resolved object
  - `boundary_argument`: Argument name containing the boundary

### 3. Directive Finder

- **Location**: `lib/gitlab/graphql/authz/directive_finder.rb`
- **Purpose**: Locates applicable directives by checking field, owner type, implementing type, and return type
- **Includes**: `TypeUnwrapper` module for unwrapping GraphQL type wrappers

### 4. Boundary Extractor

- **Location**: `lib/gitlab/graphql/authz/boundary_extractor.rb`
- **Purpose**: Extracts the authorization boundary (Project/Group) from various sources

### 5. Type Unwrapper

- **Location**: `lib/gitlab/graphql/authz/type_unwrapper.rb`
- **Purpose**: Shared module for unwrapping GraphQL type wrappers (List, NonNull, Connection)
- **Used by**: DirectiveFinder and SkipRules

### 6. Helper Module

- **Location**: `lib/gitlab/graphql/authz/authorize_granular_token.rb`
- **Purpose**: Provides the `authorize_granular_token` helper method for cleaner directive syntax
- **Included in**: `Types::BaseObject` and `Mutations::BaseMutation`
- **Method**: `authorize_granular_token(permissions:, boundary: nil, boundary_argument: nil)`

## Request Flow Timeline

### Phase 1: Request Initiation

```plaintext
1. GraphQL request arrives (query or mutation)
2. GraphQL Ruby begins parsing and validation
3. Execution begins with root fields
```

### Phase 2: Field Resolution (per field)

For each field being resolved:

```plaintext
1. GraphQL Ruby calls field extensions in order
   ├─ CallsGitaly::FieldExtension (dev/test only)
   ├─ Present::FieldExtension
   ├─ Authorize::FieldExtension
   └─ GranularTokenAuthorization ← WE ARE HERE
```

### Phase 3: Authorization Check

**Step 1: Early Exit Conditions**

```ruby
def authorize_field(object, arguments, context)
  return unless authorization_enabled?(context)  # Only authorize granular PATs with feature flag enabled
  return if SkipRules.new(@field).should_skip?  # Skip certain fields

def authorization_enabled?(context)
  token = context[:access_token]
  token && token.try(:granular?) && Feature.enabled?(:granular_personal_access_tokens_for_graphql, token.user)
end
```

- If not using a granular PAT or feature flag is disabled, granular scope authorization is skipped (legacy PATs use existing scope authorization)
- The feature flag `:granular_personal_access_tokens_for_graphql` must be enabled for the user
- Certain fields are automatically skipped:
  - **Mutation response fields** (e.g., `createIssue.issue`) - Authorization happens on the mutation itself, not the response wrapper
  - **Permission metadata fields** (e.g., `issue.userPermissions`) - These return permission information, not actual data

**Step 2: Directive Discovery**

```ruby
directive = DirectiveFinder.new(@field).find(object)
```

The `DirectiveFinder` checks for directives in this priority order, **returning the first match found**:

1. **Field-level directive** (`FIELD_DEFINITION`): Applied directly to the field

   ```ruby
   field :project, Types::ProjectType,
     directives: granular_scope_directive(
       permissions: :read_project,
       boundary_argument: :full_path
     ) do
       argument :full_path, GraphQL::Types::ID, required: true
     end
   ```

1. **Owner type directive** (`OBJECT`): Applied to the type that owns the field

   **For GraphQL types:**

   ```ruby
   class IssueType < BaseObject
     authorize_granular_token permissions: :read_issue, boundary: :project
   end
   ```

   **For mutations:**

   ```ruby
   module Mutations
     module Issues
       class Create < BaseMutation
         authorize_granular_token permissions: :create_issue, boundary_argument: :project_path
       end
     end
   end
   ```

1. **Implementing type directive** (for interfaces): Applied to the concrete type implementing an interface
   - Only checked when the field owner is an interface and an `object` is provided
   - Resolves the actual model type (e.g., `Issue`) from `GitlabSchema.types`

1. **Return type directive**: Applied to the type returned by the field
   - Always checked as a fallback if no directive found at previous levels
   - Unwraps GraphQL type wrappers to find the base type:
     - List types: `[Type]` → `Type`
     - NonNull types: `Type!` → `Type`
     - Connection types: `TypeConnection` → `Type` (e.g., `IssueConnection` → `IssueType`)
   - Works with both `boundary_argument` and `boundary` strategies
   - When using `boundary` with an `:id` argument, enables ID fallback for boundary extraction

**Step 3: Boundary Extraction**

```ruby
boundary = BoundaryExtractor.new(object:, arguments:, context:, directive:).extract
permissions = directive.arguments[:permissions].map(&:downcase)
```

**Note**: When no directive is found, `boundary` and `permissions` are both `nil`. The authorization service will return the error message: "Unable to determine boundaries and permissions for authorization".

The boundary extractor behavior:

- **For standalone resources** (`boundary: 'user'` or `boundary: 'instance'`): Returns `Authz::Boundary::NilBoundary`
- **For valid project/group resources**: Returns wrapped boundary (`ProjectBoundary` or `GroupBoundary`)
- **When resource not found**: Returns `nil` (not wrapped in NilBoundary)

Supported boundary types:

- `Authz::Boundary::ProjectBoundary` - for Project resources
- `Authz::Boundary::GroupBoundary` - for Group resources
- `Authz::Boundary::NilBoundary` - for standalone resources (user-scoped or instance-wide)

The extractor uses one of four strategies:

**Strategy A: `boundary_argument` (for mutations and query fields)**

```ruby
# Directive says: boundary_argument: 'project_path'
# Field argument: project_path: "gitlab-org/gitlab"

extract_from_argument('project_path')
  ↓
args[:project_path] = "gitlab-org/gitlab"
  ↓
resolve_path("gitlab-org/gitlab")
  ↓
Project.find_by_full_path("gitlab-org/gitlab") || Group.find_by_full_path("gitlab-org/gitlab")
  ↓
returns Project or Group instance
```

**Strategy B: `boundary` (for type fields with resolved object)**

```ruby
# Directive says: boundary: 'project'
# Object: Issue instance

extract_from_method('project')
  ↓
unwrap_object(object)  # Issue
  ↓
object_matches_boundary_type?('project')  # false (Issue ≠ Project)
  ↓
object.respond_to?(:project) # true
  ↓
object.project
  ↓
returns Project instance
```

**Strategy C: ID Fallback (for query fields with GlobalID)**

Used when:

- Directive specifies `boundary: 'project'`
- Object is nil or doesn't respond to boundary method
- Field has `:id` argument with GlobalID

```ruby
# Query: issue(id: "gid://gitlab/Issue/123")
# Directive says: boundary: 'project'
# Object: nil (query field, not resolved yet)

extract_from_id_argument
  ↓
args[:id] = "gid://gitlab/Issue/123"
  ↓
GlobalID.parse("gid://gitlab/Issue/123")
  ↓
GlobalID::Locator.locate(gid)  # Issue.find(123) - extra DB query
  ↓
extract_boundary_from_object(issue)
  ↓
issue.project
  ↓
returns Project instance
```

**Performance note**: This strategy fetches the record twice - once for authorization and once during field resolution, although the query will be cached.

**Strategy D: Standalone boundaries (for user-scoped or instance-wide resources)**

Used when:

- Directive specifies `boundary: 'user'` (user-scoped resources)
- Directive specifies `boundary: 'instance'` (instance-wide resources)

```ruby
# Directive says: boundary: 'user'
# Resource doesn't belong to a specific project/group

standalone_boundary?('user')
  ↓
returns Authz::Boundary::NilBoundary.new(nil)
  ↓
Authorization will fail unless token has appropriate permissions
```

This strategy is used for resources that don't belong to a specific project or group boundary but are user-scoped or instance-wide.

**Step 4: Authorization Check**

```ruby
authorize_with_cache!(context, boundary, permissions)
```

This method:

1. **Checks cache**: `context[:authz_cache]` to avoid duplicate checks
1. **Calls authorization service**:

   ```ruby
   ::Authz::Tokens::AuthorizeGranularScopesService.new(
     boundaries: boundary,
     permissions: permissions,
     token: context[:access_token]
   ).execute
   ```

1. **Verifies**: Token has required permissions for the boundary
1. **Raises error** if unauthorized: `raise_resource_not_available_error!(response.message)`
1. **Caches result** to avoid redundant checks

**Step 5: Field Resolution**

```ruby
yield(object, arguments, **rest)
```

If authorization passes, the field resolver executes and returns its value.

## Example Scenarios

### Scenario 1: Mutation with `boundary_argument`

**GraphQL Request:**

```graphql
mutation {
  createIssue(input: {
    projectPath: "gitlab-org/gitlab",
    title: "New issue"
  }) {
    issue { id }
  }
}
```

**Directive:**

```ruby
class Create < BaseMutation
  authorize_granular_token permissions: :create_issue, boundary_argument: :project_path
end
```

**Timeline:**

1. Extension called for `createIssue` field
1. `object` = `nil` (root mutation field)
1. Directive found on mutation class
1. Boundary extracted from `arguments[:input][:project_path]`
1. `Project.find_by_full_path("gitlab-org/gitlab")` → Project
1. Authorization service checks: Does token have `CREATE_ISSUE` permission for this project?
1. If yes: mutation executes
1. If no: raises error, mutation doesn't execute

### Scenario 2: Type with `boundary` (nested field)

**GraphQL Request:**

```graphql
query {
  project(fullPath: "gitlab-org/gitlab") {
    issues {
      nodes {
        title        # ← Authorization here
        description  # ← And here
      }
    }
  }
}
```

**Directive:**

```ruby
class IssueType < BaseObject
  authorize_granular_token permissions: :read_issue, boundary: :project
end
```

**Timeline (for `title` field):**

1. Extension called for `title` field
1. `object` = Issue instance (already resolved)
1. Directive found on `IssueType` (owner of `title` field)
1. Boundary extracted by calling `issue.project`
1. Authorization service checks: Does token have `READ_ISSUE` permission for this project?
1. Cache hit on subsequent fields (`description`, etc.) - no additional DB queries
1. If yes: field resolves and returns title
1. If no: raises error

### Scenario 3: Query field with ID fallback

**GraphQL Request:**

```graphql
query {
  issue(id: "gid://gitlab/Issue/123") {
    title
  }
}
```

**Directive:**

```ruby
class IssueType < BaseObject
  authorize_granular_token permissions: :read_issue, boundary: :project
end
```

**Timeline:**

1. Extension called for `issue` field (returns IssueType)
1. `object` = `nil` (root query field)
1. Directive found on return type (`IssueType`)
1. Boundary extraction detects: object is nil, but `:id` argument present
1. Uses ID fallback: extracts GlobalID → locates Issue → gets `issue.project`
1. Authorization service checks: Does token have `READ_ISSUE` permission for this project?
1. If yes: field resolves (Issue is fetched again by resolver)
1. If no: raises error before field resolution

## Performance Optimizations

### 1. Caching

**Per-Request Cache:**

```ruby
context[:authz_cache] = Set.new
cache_key = [permissions&.sort, boundary&.class, boundary&.namespace&.id]

# Example cache key for READ_ISSUE on a project:
# [["read_issue"], Authz::Boundary::ProjectBoundary, 123]
```

- Authorization results are cached per request using a Set
- Prevents redundant authorization checks for the same boundary and permissions
- Example: Checking 10 issue fields on the same project only hits authorization service once
- Cache key components:
  - `permissions&.sort`: Sorted array of lowercase permission strings
  - `boundary&.class`: The boundary wrapper class (e.g., `Authz::Boundary::ProjectBoundary`)
  - `boundary&.namespace&.id`: The namespace ID (varies by boundary type):
    - `ProjectBoundary`: `project.project_namespace.id`
    - `GroupBoundary`: `group.id`
    - `NilBoundary`: `nil`

### 2. Early Returns

```ruby
return unless authorization_enabled?(context)
return if SkipRules.new(@field).should_skip?
```

- Non-granular tokens skip the entire system (zero overhead)
- Feature flag check: `granular_personal_access_tokens_for_graphql` must be enabled
- Mutation response fields and permission metadata fields are automatically skipped (see Phase 3, Step 1 for details)

## Error Handling

### Authorization Failures

When authorization fails:

```ruby
raise_resource_not_available_error!(response.message)
```

**For GraphQL:**

- Returns service error in `errors` array
- Field returns `null`

**Example response:**

```json
{
  "data": { "issue": null },
  "errors": [{
    "message": "Insufficient permissions",
    "path": ["issue"]
  }]
}
```

### Edge Cases and Error Scenarios

#### Missing Configuration Errors

1. **No directive found (with granular PAT)**
   - **Behavior**: Authorization proceeds with `boundary: nil, permissions: nil`
   - **Result**: Authorization service returns error
   - **Error message**: `"Unable to determine boundaries and permissions for authorization"`
   - **Note**: All fields accessed with granular PATs must have directives

1. **Directive has empty permissions array**
   - **Behavior**: Authorization proceeds with `permissions: []` (boundary provided)
   - **Result**: Authorization service returns error
   - **Error message**: `"Unable to determine permissions for authorization"`
   - **Cause**: Directive defined with `permissions: []`

#### Boundary Resolution Errors

1. **Boundary extraction returns nil (resource not found)**
   - **Behavior**: Authorization proceeds with `boundary: nil` (permissions still provided)
   - **Result**: Authorization service returns error
   - **Error message**: `"Unable to determine boundaries for authorization"`
   - **Causes**:
     - Invalid path/GlobalID that doesn't resolve to a resource
     - Object missing expected association (e.g., `issue.project` returns `nil`)
     - Directive has neither `boundary` nor `boundary_argument` configured
   - **Note**: This is different from standalone boundaries which return `NilBoundary` object

1. **Invalid GlobalID format**
   - **Behavior**: `GlobalID.parse("invalid")` returns `nil`
   - **Result**: Boundary extraction returns `nil` → authorization error
   - **Error message**: `"Unable to determine boundaries for authorization"`
   - **Note**: Fails gracefully without raising exceptions

1. **Boundary method returns nil**
   - **Behavior**: `issue.project` returns `nil`
   - **Result**: Returns `nil` → authorization error
   - **Error message**: `"Unable to determine boundaries for authorization"`
   - **Common causes**: Soft-deleted associations, orphaned records

1. **GlobalID points to non-existent record**
   - **Behavior**: `GlobalID::Locator.locate(gid)` raises `ActiveRecord::RecordNotFound`, rescued and returns `nil`
   - **Result**: Boundary extraction returns `nil` → authorization error
   - **Error message**: `"Unable to determine boundaries for authorization"`

#### Configuration Errors

1. **Object doesn't respond to boundary method**
   - **Behavior**: Raises `ArgumentError: "Boundary method 'project' not found on Project"`
   - **Cause**: Using `boundary: 'project'` but object is wrong type
   - **Exceptions**:
     - If field has `:id` argument, uses ID fallback instead
     - If object type matches boundary name, returns object directly
   - **Example**:

     ```ruby
     # IssueType has: boundary: 'project'
     # Field: project.issue(iid: "1")
     # object = Project (not Issue)
     # Project matches 'project' → returns Project
     ```

1. **Multiple directives found**
   - **Behavior**: Uses first match in priority order (field → owner → implementing type → return type)
   - **Result**: May not use expected directive if multiple apply
   - **Best practice**: Apply directive at only one level per field to avoid confusion
   - **Note**: The directive finder stops at the first match and does not check subsequent levels

## Helper Method Syntax

Helper methods are provided for applying granular token authorization with cleaner syntax than direct directive usage.

### Type and Mutation Level: `authorize_granular_token`

Available on all GraphQL types (via `Types::BaseObject`) and mutations (via `Mutations::BaseMutation`).

**Method Signature:**

```ruby
authorize_granular_token(permissions:, boundary: nil, boundary_argument: nil)
```

**Parameters:**

- `permissions`: Symbol representing the required permission (e.g., `:read_issue`). Can also be an array of permissions.
- `boundary`: Symbol representing the method to call on the resolved object to extract the boundary (e.g., `:project`). Use `:user` or `:instance` for standalone resources.
- `boundary_argument`: Symbol representing the argument name containing the boundary path (e.g., `:project_path`).

**Example:**

```ruby
class IssueType < BaseObject
  authorize_granular_token permissions: :read_issue, boundary: :project
end
```

### Field Level: `granular_scope_directive`

For applying directives to individual fields, use the class method on `Types::BaseField`.

**Method Signature:**

```ruby
granular_scope_directive(permissions:, boundary: nil, boundary_argument: nil)
```

**Parameters:** Same as `authorize_granular_token`

**Example:**

```ruby
field :project, Types::ProjectType,
  directives: granular_scope_directive(
    permissions: :read_project,
    boundary_argument: :full_path
  )
```

## Directive Application Rules

### Directive Locations

The `GranularScope` directive can be applied at two locations:

1. **`FIELD_DEFINITION`** - Applied directly to individual fields

   ```ruby
   field :project, Types::ProjectType,
     directives: granular_scope_directive(
       permissions: :read_project,
       boundary_argument: :full_path
     )
   ```

   - Use for fields that need different permissions than their owner type
   - Use for mutations and query fields to specify boundary extraction strategy

1. **`OBJECT`** - Applied to GraphQL object types

   ```ruby
   class IssueType < BaseObject
     authorize_granular_token permissions: :read_issue, boundary: :project
   end
   ```

   - Applies to all fields on the type (unless overridden by field-level directive)
   - Use when all fields on a type require the same permissions

### When `boundary` applies

✅ Fields **on** the type (e.g., `issue.title` when `IssueType` has directive)
✅ Query fields with `:id` argument returning the type (enables ID fallback)
✅ Standalone resources using `boundary: 'user'` or `boundary: 'instance'`
❌ Query fields **without** `:id` argument returning the type (object not available, raises ArgumentError)

### When `boundary_argument` applies

✅ Root mutations
✅ Root query fields
✅ Any field that receives boundary as an argument
✅ Fields returning types with `boundary_argument` directive

### Standalone Boundaries

Use `boundary: 'user'` or `boundary: 'instance'` for resources that don't belong to a specific project or group:

```ruby
class UserSettingType < BaseObject
  authorize_granular_token permissions: :read_user_settings, boundary: :user
end
```

These directives return `NilBoundary` which will be validated by the authorization service but won't be tied to a specific project/group namespace.

## See Also

- [Granular Personal Access Tokens Documentation](granular_personal_access_tokens.md)

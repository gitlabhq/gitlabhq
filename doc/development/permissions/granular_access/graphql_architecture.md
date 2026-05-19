---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: GraphQL Granular Token Authorization Architecture
---

This document explains how the `GranularTokenAuthorization` field extension works to enforce granular Personal Access Token (PAT) permissions on GraphQL queries and mutations. For a step-by-step implementation guide, see [GraphQL implementation guide](graphql_implementation_guide.md).

## Overview

The granular token authorization system adds fine-grained permission checks to GraphQL fields based on directives applied to types, fields, and mutations. It ensures that granular PATs can only access resources they have explicit permissions for within specific project or group boundaries.

**Feature Flag**: This feature requires the `granular_personal_access_tokens` feature flag to be enabled for the token's user. When the flag is disabled, granular PATs do not work for GraphQL requests.

## Architecture Components

### 1. Field Extension

- **Location**: `lib/gitlab/graphql/authz/granular_token_authorization.rb`
- **Purpose**: Intercepts field resolution to perform authorization checks
- **Applied to**: All GraphQL fields via `Types::BaseField`

### 2. Directive

- **Location**: `app/graphql/directives/authz/granular_scope.rb`
- **Purpose**: Declares required permissions and boundary extraction strategy
- **Arguments**:
  - `permissions`: Array of required permission strings (e.g., `['read_issue']`)
  - `boundary`: Method name to extract boundary from resolved object
  - `boundary_argument`: Argument name containing the boundary
  - `boundary_type`: The type of authorization boundary (`project`, `group`, `user`, `instance`). Used for validation and documentation of the permission boundary

### 3. Directive Finder

- **Location**: `lib/gitlab/graphql/authz/directive_finder.rb`
- **Purpose**: Locates applicable directives by checking field, owner type, implementing type, and return type
- **Includes**: `TypeUnwrapper` module for unwrapping GraphQL type wrappers

### 4. Boundary Extractor

- **Location**: `lib/gitlab/graphql/authz/boundary_extractor.rb`
- **Purpose**: Extracts the authorization boundary from various sources

### 5. Type Unwrapper

- **Location**: `lib/gitlab/graphql/authz/type_unwrapper.rb`
- **Purpose**: Shared module for unwrapping GraphQL type wrappers (List, NonNull, Connection)
- **Used by**: DirectiveFinder and SkipRules

### 6. Helper Module

- **Location**: `lib/gitlab/graphql/authz/authorize_granular_token.rb`
- **Purpose**: Provides the `authorize_granular_token` helper method for cleaner directive syntax
- **Included in**: `Types::BaseObject`, `Types::BaseField`, and `Mutations::BaseMutation`
- **Method**: `authorize_granular_token(permissions:, boundary_type:, boundary: nil, boundary_argument: nil)`
- **Validation**: Permissions are validated by the `gitlab:permissions:validate` Rake task against `Authz::PermissionGroups::Assignable.all_permissions`.

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
  return unless authorization_enabled?(context)  # Only authorize granular PATs
  return if SkipRules.new(@field).should_skip?  # Skip certain fields
  # ...
end

def authorization_enabled?(context)
  token = context[:access_token]
  token && token.try(:granular?)
end
```

- If not using a granular PAT, granular scope authorization is skipped (legacy PATs use existing scope authorization)
- Certain fields are automatically skipped:
  - **Mutation response fields** (e.g., `createIssue.issue`) - Authorization happens on the mutation itself, not the response wrapper
  - **Permission metadata fields** (e.g., `issue.userPermissions`) - These return permission information, not actual data

**Step 2: Directive Discovery**

```ruby
directive = DirectiveFinder.new(@field).find(object)
```

The `DirectiveFinder` checks for directives in this priority order, **returning the first match found**:

1. **Field-level directive** (`FIELD_DEFINITION`): Applied directly to the field
1. **Owner type directive** (`OBJECT`): Applied to the type that owns the field
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
permissions = directive.arguments[:permissions]
```

> [!note]
> When no directive is found, `boundary` and `permissions` are both `nil`. The authorization service will return the error message: "Unable to determine boundaries and permissions for authorization".

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

The boundary method must be one of the valid accessor methods: `project`, `group`, or `itself`. An `ArgumentError` is raised for any other value.

```ruby
# Directive says: boundary: 'project'
# Object: Issue instance

extract_from_method('project')
  ↓
unwrap_object(object)  # Issue
  ↓
object_matches_boundary_type?('project')  # false (Issue ≠ Project)
  ↓
VALID_BOUNDARY_ACCESSOR_METHODS.include?('project')  # true
  ↓
object.respond_to?(:project) # true
  ↓
object.project
  ↓
returns Project instance
```

When using `boundary: 'itself'`, the object is returned as its own boundary. This is useful for types that are themselves a Project or Group:

```ruby
# Directive says: boundary: 'itself'
# Object: Project instance

extract_from_method('itself')
  ↓
unwrap_object(object)  # Project
  ↓
object_matches_boundary_type?('itself')  # false (Project ≠ Itself)
  ↓
VALID_BOUNDARY_ACCESSOR_METHODS.include?('itself')  # true
  ↓
object.itself  # Ruby's Object#itself returns self
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
@boundary_accessor.to_sym  # :user
  ↓
Authz::Boundary.for(:user)
  ↓
returns Authz::Boundary::NilBoundary.new(:user)
  ↓
Authorization checks token has appropriate permissions
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
  authorize_granular_token permissions: :create_issue, boundary_argument: :project_path, boundary_type: :project
end
```

**Timeline:**

1. Extension called for `createIssue` field
1. `object` = `nil` (root mutation field)
1. Directive found on mutation class
1. Boundary extracted from `arguments[:input][:project_path]`
1. `Project.find_by_full_path("gitlab-org/gitlab")` → Project
1. Authorization service checks: Does token have `create_issue` permission for this project?
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
  authorize_granular_token permissions: :read_issue, boundary: :project, boundary_type: :project
end
```

**Timeline (for `title` field):**

1. Extension called for `title` field
1. `object` = Issue instance (already resolved)
1. Directive found on `IssueType` (owner of `title` field)
1. Boundary extracted by calling `issue.project`
1. Authorization service checks: Does token have `read_issue` permission for this project?
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
  authorize_granular_token permissions: :read_issue, boundary: :project, boundary_type: :project
end
```

**Timeline:**

1. Extension called for `issue` field (returns IssueType)
1. `object` = `nil` (root query field)
1. Directive found on return type (`IssueType`)
1. Boundary extraction detects: object is nil, but `:id` argument present
1. Uses ID fallback: extracts GlobalID → locates Issue → gets `issue.project`
1. Authorization service checks: Does token have `read_issue` permission for this project?
1. If yes: field resolves (Issue is fetched again by resolver)
1. If no: raises error before field resolution

## Performance Optimizations

### 1. Caching

**Per-Request Cache:**

```ruby
context[:authz_cache] = Set.new
cache_key = [permissions&.sort, boundary&.class, boundary&.namespace&.id]

# Example cache key for `read_issue` on a project:
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

1. **Invalid boundary method**
   - **Behavior**: Raises `ArgumentError: "Invalid boundary method: 'foo'"`
   - **Cause**: Using a `boundary` value not in the valid accessor methods (`project`, `group`, `itself`)
   - **Note**: This validation runs before checking if the object responds to the method

1. **Object doesn't respond to boundary method**
   - **Behavior**: Raises `ArgumentError: "Boundary method 'project' not found on Project"`
   - **Cause**: Using a valid boundary method (e.g., `boundary: 'project'`) but the object doesn't have that method
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

1. **Invalid permission name**
   - **Behavior**: Detected by the `gitlab:permissions:validate` Rake task
   - **Cause**: Using a permission symbol that doesn't exist in `Authz::PermissionGroups::Assignable.all_permissions`
   - **Note**: This validation runs as part of CI to ensure all directive permissions reference valid assignable permissions

1. **Multiple directives found**
   - **Behavior**: Uses first match in priority order (field → owner → implementing type → return type)
   - **Result**: May not use expected directive if multiple apply
   - **Best practice**: Apply directive at only one level per field to avoid confusion
   - **Note**: The directive finder stops at the first match and does not check subsequent levels

## See Also

- [GraphQL implementation guide](graphql_implementation_guide.md)

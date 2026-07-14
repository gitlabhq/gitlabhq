---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: GraphQL Granular Token Authorization Architecture
---

This document explains how `GranularScopeAuthorization` enforces granular Personal Access Token (PAT) permissions on GraphQL types, fields, and mutations.
For a step-by-step implementation guide, see [GraphQL implementation guide](graphql_implementation_guide.md).

## Overview

The granular token authorization system adds fine-grained permission checks to GraphQL based on `authorize_granular_token` directives applied to types, fields, and mutations.
It ensures that granular PATs can only access resources they have explicit permissions for within specific project, group, user, or instance boundaries.

**Feature flag**: This feature requires the `granular_personal_access_tokens` feature flag to be enabled for the token's user.
When the flag is disabled, granular PATs do not work for GraphQL requests.

## Architecture components

### 1. Authorization check

- **Location**: `lib/gitlab/graphql/authz/granular_scope_authorization.rb`
- **Purpose**: Evaluates the `authorize_granular_token` directives declared on a type, field, or mutation against the request's granular PAT
- **Public methods**:
  - `ok?(object, context, arguments: nil)`: Returns `true` or `false`. Used for type-level and field-level authorization.
  - `authorize!(object, context, arguments: nil)`: Raises `Gitlab::Graphql::Errors::ArgumentError` with the denial message when authorization fails. Used for mutations.

### 2. Directive

- **Location**: `app/graphql/directives/authz/granular_scope.rb`
- **Purpose**: Declares required permissions and boundary extraction strategy
- **Arguments**:
  - `permissions`: Array of required permission strings (for example, `['read_issue']`).
  - `boundary`: Method name to extract boundary from resolved object.
  - `boundary_argument`: Argument name containing the boundary.
  - `boundary_type`: The type of authorization boundary (`project`, `group`, `user`,
    `instance`). Used for validation and documentation of the permission boundary.
  - `traversal`: When `true`, the directive verifies only that the token is scoped to the
    boundary (`read_boundary`). The listed permissions are not enforced on the field
    itself. Use for entry-point fields like `Query.group(fullPath:)` where downstream
    fields enforce the real permissions.

### 3. Boundary extractor

- **Location**: `lib/gitlab/graphql/authz/boundary_extractor.rb`
- **Purpose**: Resolve the object the token must be scoped to. The object can be a project, group, `:user`, or `:instance`, but is not limited to these.
- **Behavior**: Extracts the boundary from the source each directive declares: directives with `boundary_argument` read from the field or mutation arguments, all other directives read from the already-resolved object.

### 4. Helper module

- **Location**: `lib/gitlab/graphql/authz/authorize_granular_token.rb`
- **Purpose**: Provides the `authorize_granular_token` helper method for cleaner directive syntax
- **Included in**: `Types::BaseObject`, `Types::BaseField`, and `Mutations::BaseMutation`
- **Method**: `authorize_granular_token(permissions:, boundary_type:, boundary: nil, boundary_argument: nil)`
- **Validation**: Permissions are validated by the `gitlab:permissions:validate` Rake task against `Authz::PermissionGroups::Assignable.all_permissions`.

### 5. Authorization service

- **Location**: `app/services/authz/tokens/authorize_granular_scopes_service.rb`
- **Purpose**: Checks whether the token holds the required permissions on the resolved boundaries
- **Returns**: A `ServiceResponse.success`. On failure, a `ServiceResponse.error` with an error message describing which permissions the token is missing.

## Request flow timeline

### Phase 1: Authorization entry points

Authorization runs at three points, each constructing `GranularScopeAuthorization` from the directives declared at that level.

| Level | Entry point | Directives source | On failure |
| ----- | ----------- | ----------------- | ---------- |
| Type | `Types::BaseObject.authorized?` | The type's directives | Returns `false`, which denies access |
| Field | `Types::BaseField#field_authorized?` | The field's directives | Returns `false` for query fields, raises a resource-not-available error for `MutationType` fields |
| Mutation | `Mutations::BaseMutation#authorized?` | The mutation class's directives | Raises `Gitlab::Graphql::Errors::ArgumentError` |

### Phase 2: Authorization check

At each entry point, `GranularScopeAuthorization` evaluates the request in these steps:

**Step 1: Token check**

The check applies only to granular PATs.
Legacy PATs pass this step and rely on the existing scope authorization, unless enforcement applies (see [Phase 3](#phase-3-legacy-token-enforcement)).

**Step 2: Directive check**

If no granular directives are declared, authorization fails.

**Step 3: Boundary extraction**

The boundaries are extracted from the source each directive declares: the resolved object for type-level checks, or the arguments for mutations and root query fields.
For details, see [Boundary extraction](#boundary-extraction).

**Step 4: Authorization**

`AuthorizeGranularScopesService` checks whether the token holds the required permissions on the extracted boundaries, and the result is cached.

### Phase 3: Legacy token enforcement

Granular permission checks also apply to legacy (non-granular) tokens when a boundary's root namespace enforces granular tokens.
`AuthorizeGranularScopesService` reads each boundary's root namespace setting through `granular_tokens_enforced?`:

- When enforcement is on, the legacy token is held to the same permission checks as a granular token.
- When enforcement is off, the legacy token passes and relies on the existing scope authorization.

## Boundary extraction

Each directive declares where its boundary comes from, and `BoundaryExtractor` reads from that source.
Type-level checks authorize an object that GraphQL has already resolved, so the boundary is reached by calling a method on that object.
Mutations and root query fields authorize before any object is resolved, so the boundary must be derived from the arguments.

### 1. From a resolved object (types and nested fields)

Directives without a `boundary_argument` read from the resolved object.
The extractor reads the `boundary` method from the directive and resolves the boundary from the already-resolved object:

- `boundary: :itself` returns the object as its own boundary. Use this for types that are themselves a Project or Group.
- Any other value calls that method on the object.

For example, `ProjectType` is its own boundary:

```ruby
authorize_granular_token permissions: :read_project, boundary: :itself, boundary_type: :project
# boundary => the Project itself
```

`IssueType` reaches its boundary through a method:

```ruby
authorize_granular_token permissions: :read_issue, boundary: :project, boundary_type: :project
# boundary => issue.project
```

### 2. From arguments (mutations and root query fields)

Directives with a `boundary_argument` read from the arguments.
This applies to mutations and to root query fields, where no parent object exists to reach a boundary from.
The extractor reads the `boundary_argument` from the directive and locates the record:

- A GlobalID is located through `GitlabSchema.find_by_gid` (forced with `Gitlab::Graphql::Lazy`), so the lookup participates in GraphQL batch loading.
- A full-path string is located through `Project.find_by_full_path` or `Group.find_by_full_path`.
- A Project or Group record is returned directly.
- Any other record has the directive's `boundary` method called on it to reach the Project or Group.

When the argument resolves to a Project or Group directly, only `boundary_argument` is needed:

```ruby
authorize_granular_token permissions: :create_issue, boundary_argument: :project_path, boundary_type: :project
# boundary => Project.find_by_full_path(project_path)
```

When the argument resolves to some other record, add `boundary` to reach the Project or Group from it:

```ruby
authorize_granular_token permissions: :create_note, boundary_argument: :id, boundary: :project, boundary_type: :project
# boundary => located_record.project
```

## Multiple boundaries

A type can declare more than one boundary when the same resource can belong to different boundary types.
A concrete boundary is a specific Project or Group record.
A standalone boundary is the `user` or `instance` boundary type, which does not belong to a project or group.

Concrete boundaries take precedence.
A standalone boundary is used only when no concrete boundary resolves.
A directive is also skipped when its resolved object does not match its declared `boundary_type`, so the same `boundary` method can serve more than one type.

For example, `Ci::RunnerType` declares three boundaries because a runner can belong to a project, belong to a group, or be instance-wide:

```ruby
authorize_granular_token(
  permissions: :read_runner,
  boundaries: [
    { boundary: :owner, boundary_type: :project },
    { boundary: :owner, boundary_type: :group },
    { boundary: :instance, boundary_type: :instance }
  ]
)
```

The boundary that applies depends on the runner:

- For a project runner, `runner.owner` is a Project, so the project boundary resolves and is used.
- For a group runner, `runner.owner` is a Group, so the group boundary resolves and is used.
- For an instance runner, `runner.owner` is neither a Project nor a Group, so both concrete directives are skipped. The standalone `instance` boundary is used instead, and the token is checked for `read_runner` on the instance.

The standalone boundary is preferred over the concrete boundaries only in the last case, where the runner has no owning project or group.

## Example scenarios

### Scenario 1: Mutation with `boundary_argument`

A `createIssue` mutation passes the project as a path argument:

```graphql
mutation {
  createIssue(input: { projectPath: "gitlab-org/gitlab", title: "New issue" }) {
    issue { id }
  }
}
```

`Mutations::Issues::Create` declares:

```ruby
authorize_granular_token permissions: :create_issue, boundary_argument: :project_path, boundary_type: :project
```

1. GraphQL Ruby calls `Mutations::BaseMutation#authorized?` before the mutation runs.
1. `BoundaryExtractor` reads `project_path` and resolves the Project through `Project.find_by_full_path`.
1. `AuthorizeGranularScopesService` checks whether the token has `create_issue` on that project.
1. When the token has the permission, the mutation runs. Otherwise, `Gitlab::Graphql::Errors::ArgumentError` is raised.

### Scenario 2: Query type with `boundary`

A query reads fields on resolved issues:

```graphql
query {
  project(fullPath: "gitlab-org/gitlab") {
    issues {
      nodes { title }
    }
  }
}
```

`IssueType` declares:

```ruby
authorize_granular_token permissions: :read_issue, boundary: :project, boundary_type: :project
```

1. When each `Issue` is resolved, `Types::BaseObject.authorized?` runs for `IssueType`.
1. `BoundaryExtractor` calls `issue.project` to reach the boundary.
1. `AuthorizeGranularScopesService` checks whether the token has `read_issue` on that project.
1. When the token has the permission, the issue resolves. Otherwise, access is denied and the check returns `false`.

### Scenario 3: Mutation with a GlobalID and `boundary`

A `createNote` mutation passes a GlobalID, and the boundary is reached from the located record:

```ruby
authorize_granular_token permissions: :create_note, boundary_argument: :id, boundary: :project, boundary_type: :project
```

For the argument `id: "gid://gitlab/Issue/1"`, `BoundaryExtractor` locates the Issue through `GitlabSchema.find_by_gid`, then calls `issue.project` to reach the boundary.

### Scenario 4: Root query field with `boundary_argument`

A root query field resolves computed data for a namespace passed as an argument, so there is no parent object and no resolved record to reach a boundary from:

```graphql
query {
  aiToolRules(fullPath: "gitlab-org") {
    nodes { id }
  }
}
```

The field's resolver declares:

```ruby
authorize_granular_token permissions: :read_ai_tool_rule, boundary_argument: :full_path, boundary_type: :group
```

1. GraphQL Ruby calls `Types::BaseField#authorized?` with the field arguments before the resolver runs.
1. `BoundaryExtractor` reads `full_path` and resolves the Group through `Group.find_by_full_path`.
1. `AuthorizeGranularScopesService` checks whether the token has `read_ai_tool_rule` on that group.
1. When the token has the permission, the field resolves. Otherwise, the field is nulled.

Directives declared on a resolver class are applied to the fields the resolver is mounted on, so `authorize_granular_token` can be declared either on the resolver or on the field definition itself with `directives: granular_scope_directive(...)`.

## Performance optimizations

### 1. Per-request authorization cache

Authorization results are cached per request.
Multiple fields that resolve to the same boundary and permissions reuse the cached result, so the authorization service runs only once for them.

### 2. Batched boundary preloading

Resolving a boundary from each node in a collection one at a time produces an N+1 query.
For example, if `IssueType` declares `authorize_granular_token permissions: :read_issue, boundary: :project`, then for each resolved issue object the extractor calls `issue.project`, which creates an N+1 problem.

`BoundaryExtractors::Preloader` solves this by preloading the collection's nodes before authorization runs:

- The preloader batch-loads the boundary associations across all nodes in one set of queries, then caches the loaded records in `Gitlab::SafeRequestStore`.
- The boundary extractors reuse these cached records instead of querying again.

### 3. Enforcement preloading

Legacy tokens are blocked from accessing a namespace's resources when the namespace setting that enforces granular tokens is enabled.
For more information, see [issue 20180](https://gitlab.com/gitlab-org/gitlab/-/issues/20180).

Instead of loading the root namespace of a boundary and its settings on every check, GitLab preloads them and stores the `granular_tokens_enforced?` value in a cache.
`AuthorizeGranularScopesService` later reads this cached value.

## Error handling

### 1. Authorization failures

When authorization fails:

- Mutations raise `Gitlab::Graphql::Errors::ArgumentError`, with an error message that tells the user which granular permissions the token is missing. The message is carried into the GraphQL response `errors` array.
- Type-level checks return `false`, which denies access to the object.
- Field-level checks return `false` for query fields, which denies access. Fields on `MutationType` instead raise a resource-not-available error, so the mutation response populates `errors`.

```json
{
  "data": { "issue": null },
  "errors": [{
    "message": "Access denied: This operation requires a fine-grained personal access token with the following project permissions: [Issue: Read].",
    "path": ["issue"]
  }]
}
```

### 2. Boundary resolution errors

The extractor returns an empty array when it cannot resolve a boundary.
This happens when a path or GlobalID does not match a record, when a boundary method returns `nil`, or when the directive is missing the `boundary` or `boundary_argument` it needs.

`AuthorizeGranularScopesService` treats an empty boundary set with requested permissions as an unresolved resource and returns a `404 Not Found` error.
Returning `404 Not Found` rather than a permission error avoids disclosing whether the resource exists.

### 3. Configuration errors

These errors indicate that a directive is misconfigured, and are surfaced during development or validation rather than at request time:

- An invalid permission name raises `InvalidInputError` in `AuthorizeGranularScopesService`, and is also caught by the `gitlab:permissions:validate` Rake task against `Authz::PermissionGroups::Assignable.all_permissions`.
- A `boundaries:` entry that is not a Hash with a `boundary_type` key raises `ArgumentError`.
- Passing `traversal: true` to a type-level `authorize_granular_token` raises `ArgumentError`. Use `granular_scope_directive(traversal: true)` on the field definition instead.

## See also

- [GraphQL implementation guide](graphql_implementation_guide.md)

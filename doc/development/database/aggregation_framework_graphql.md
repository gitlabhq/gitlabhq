---
stage: Analytics
group: Optimize
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Aggregation Engine GraphQL Integration
---

This document describes how to integrate aggregation engine with GraphQL using the `Gitlab::Database::Aggregation::Graphql::Mounter` module.

## Overview

The GraphQL integration automatically generates:

- **Query field** for mounted engine
- **Filter arguments** based on engine filter definitions
- **Order argument** based on engine dimensions & metrics definitions. Snake cased dimension and metric identifiers can be used as order identifier
- **Response types** with dimensions and metrics as fields
- **Parameterized fields** for dimensions and metrics with parameters
- **Pagination**: aggregation results are automatically paginated using **OFFSET** pagination

## Mounting an Engine

Use the `mount_aggregation_engine` method in your GraphQL type to expose an aggregation engine:

```ruby
module Types
  class ProjectType < BaseObject
    extend Gitlab::Database::Aggregation::Graphql::Mounter

    mount_aggregation_engine(
      IssueAggregationEngine,
      field_name: 'issue_analytics',
      description: 'Issue analytics aggregation'
    ) do
      # Define base aggregation scope. Build your own scope or inherit one from parent object.
      def aggregation_scope
        object.issues
      end
    end
  end
end
```

- You MUST take care of authorization and proper base scope or define elevated permission requirements for the GraphQL field.
- Note: ALL filters, metrics & dimensions are exposed automatically.

### Mounter Options

| Option | Type | Description |
|--------|------|-------------|
| `field_name` | String/Symbol | The GraphQL field name. Defaults to `:aggregation` |
| `types_prefix` | String/Symbol | Prefix for all child types like `*AggregationResponse` and `*AggregationDimensions`. Defaults to `field_name` |
| `description` | String | Description for the GraphQL field |

## Example GraphQL Query for generated GraphQL subtree

```graphql
query IssueAnalytics($projectId: ID!) {
  project(fullPath: $projectId) {
    issueAnalytics(
      state: ["opened", "closed"]
      createdAtFrom: "2024-01-01"
      createdAtTo: "2024-12-31"
      orderBy: [{ identifier: "totalCount", direction: DESC }]
      first: 10
    ) {
      nodes {
        dimensions {
          createdAt(granularity: "monthly")
        }
        totalCount
        meanWeight
        highQuantile: durationQuantile(0.9)
        medianQuantile: durationQuantile(0.5)
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
}
```

## Custom Request Validations

You can add custom validation logic to discard specific aggregation requests while maintaining the GraphQL schema. This is useful when you need to enforce custom runtime constraints on specific requests.

Raise a `GraphQL::ExecutionError` to reject the request with a custom error message.

To add custom validations, override the `validate_request!` method in the mounting block:

```ruby
module Types
  class ProjectType < BaseObject
    extend Gitlab::Database::Aggregation::Graphql::Mounter

    mount_aggregation_engine(IssueAggregationEngine) do
      # Other configuration options...
      # Custom validation logic
      def validate_request!(engine_request)
        if engine_request.dimensions.empty?
          raise GraphQL::ExecutionError, 'At least one dimension must be specified'
        end
      end
    end
  end
end
```

The `validate_request!` method receives a `Gitlab::Database::Aggregation::Request` object containing `dimensions`, `metrics`, `filters` and `order` specifications.

## Dimensions for ActiveRecord association

Dimensions can be marked as associations using the `association: true` option. This changes how the dimension is exposed in GraphQL, automatically resolving the associated model instead of exposing just the ID.

### Defining Association Dimensions

In your aggregation engine, declare a dimension with `association: true`:

```ruby
class AgentPlatformSessions < Gitlab::Database::Aggregation::ClickHouse::Engine
  dimensions do
    column :flow_type, :string, description: 'Type of session'
    column :user_id, :integer, description: 'Session owner', association: true
  end
end
```

### GraphQL Schema Impact

When a dimension is marked as an association object is exposed instead of raw `*_id` field. Dimension above will transform to `field :user, Types::UserType, ...` in GraphQL with batch loading by ID.
You can order by the association ID using the association name without `_id` suffix (e.g., `orderBy: [{ identifier: "user", direction: DESC }]`).

Note: you must ensure all proper authorization checks on association GraphQL type (e.g. `authorize :read_user`)

### Custom Association Configuration

By default, the association model and GraphQL type are inferred from the dimension name:

- Model: `user_id` → `User`
- GraphQL type: `User` → `Types::UserType`

You can customize this behavior by passing a hash to the `association` option:

```ruby
dimensions do
  column :author_id, :integer,
    description: 'Issue author',
    association: { model: User }
    # or model and GraphQL type
    # association: { model: User, graphql_type: Types::CurrentUserType }
end
```

### GraphQL Query Examples

**Without association**

```graphql
query {
  project(fullPath: "gitlab-org/gitlab") {
    aiUsage {
      agentPlatformSessions {
        nodes {
          dimensions {
            userId  # Returns: 123 (integer)
          }
        }
      }
    }
  }
}
```

**With association**

```graphql
query {
  project(fullPath: "gitlab-org/gitlab") {
    aiUsage {
      agentPlatformSessions(
        userId: [1, 2]  # Filter still uses original dimension identifier
        orderBy: [{ identifier: "user", direction: DESC }]  # Order uses association name
      ) {
        nodes {
          dimensions {
            user {  # Returns: full User object
              id
              username
              name
            }
          }
        }
      }
    }
  }
}
```

## Related Documentation

- [Aggregation Framework](aggregation_framework.md)
- [GraphQL Development](../api_graphql_styleguide.md)

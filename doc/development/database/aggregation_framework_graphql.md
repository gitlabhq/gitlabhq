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
          authorId
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

## Related Documentation

- [Aggregation Framework](aggregation_framework.md)
- [GraphQL Development](../api_graphql_styleguide.md)

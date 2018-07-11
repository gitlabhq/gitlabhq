# GraphQL API

## Authentication

Authentication happens through the `GraphqlController`, right now this
uses the same authentication as the Rails application. So the session
can be shared.

It is also possible to add a `private_token` to the querystring, or
add a `HTTP_PRIVATE_TOKEN` header.

### Authorization

Fields can be authorized using the same abilities used in the Rails
app. This can be done using the `authorize` helper:

```ruby
module Types
  class QueryType < BaseObject
    graphql_name 'Query'

    field :project, Types::ProjectType, null: true, resolver: Resolvers::ProjectResolver do
      authorize :read_project
    end
  end
```

The object found by the resolve call is used for authorization.

This works for authorizing a single record, for authorizing
collections, we should only load what the currently authenticated user
is allowed to view. Preferably we use our existing finders for that.

## Types

When exposing a model through the GraphQL API, we do so by creating a
new type in `app/graphql/types`.

When exposing properties in a type, make sure to keep the logic inside
the definition as minimal as possible. Instead, consider moving any
logic into a presenter:

```ruby
class Types::MergeRequestType < BaseObject
  present_using MergeRequestPresenter

  name 'MergeRequest'
end
```

An existing presenter could be used, but it is also possible to create
a new presenter specifically for GraphQL.

The presenter is initialized using the object resolved by a field, and
the context.

### Connection Types

GraphQL uses [cursor based
pagination](https://graphql.org/learn/pagination/#pagination-and-edges)
to expose collections of items. This provides the clients with a lot
of flexibility while also allowing the backend to use different
pagination models.

To expose a collection of resources we can use a connection type. This wraps the array with default pagination fields. For example a query for project-pipelines could look like this:

```
query($project_path: ID!) {
  project(fullPath: $project_path) {
    pipelines(first: 2) {
      pageInfo {
        hasNextPage
        hasPreviousPage
      }
      edges {
        cursor
        node {
          id
          status
        }
      }
    }
  }
}
```

This would return the first 2 pipelines of a project and related
pagination info., ordered by descending ID. The returned data would
look like this:

```json
{
  "data": {
    "project": {
      "pipelines": {
        "pageInfo": {
          "hasNextPage": true,
          "hasPreviousPage": false
        },
        "edges": [
          {
            "cursor": "Nzc=",
            "node": {
              "id": "77",
              "status": "FAILED"
            }
          },
          {
            "cursor": "Njc=",
            "node": {
              "id": "67",
              "status": "FAILED"
            }
          }
        ]
      }
    }
  }
}
```

To get the next page, the cursor of the last known element could be
passed:

```
query($project_path: ID!) {
  project(fullPath: $project_path) {
    pipelines(first: 2, after: "Njc=") {
      pageInfo {
        hasNextPage
        hasPreviousPage
      }
      edges {
        cursor
        node {
          id
          status
        }
      }
    }
  }
}
```

### Exposing permissions for a type

To expose permissions the current user has on a resource, you can call
the `expose_permissions` passing in a separate type representing the
permissions for the resource.

For example:

```ruby
module Types
  class MergeRequestType < BaseObject
    expose_permissions Types::MergeRequestPermissionsType
  end
end
```

The permission type inherits from `BasePermissionType` which includes
some helper methods, that allow exposing permissions as non-nullable
booleans:

```ruby
class MergeRequestPermissionsType < BasePermissionType
  present_using MergeRequestPresenter

  graphql_name 'MergeRequestPermissions'

  abilities :admin_merge_request, :update_merge_request, :create_note

  ability_field :resolve_note,
                description: 'Whether or not the user can resolve disussions on the merge request'
  permission_field :push_to_source_branch, method: :can_push_to_source_branch?
end
```

- **`permission_field`**: Will act the same as `graphql-ruby`'s
  `field` method but setting a default description and type and making
  them non-nullable. These options can still be overridden by adding
  them as arguments.
- **`ability_field`**: Expose an ability defined in our policies. This
  takes behaves the same way as `permission_field` and the same
  arguments can be overridden.
- **`abilities`**: Allows exposing several abilities defined in our
  policies at once. The fields for these will all have be non-nullable
  booleans with a default description.

## Resolvers

To find objects to display in a field, we can add resolvers to
`app/graphql/resolvers`.

Arguments can be defined within the resolver, those arguments will be
made available to the fields using the resolver.

We already have a `FullPathLoader` that can be included in other
resolvers to quickly find Projects and Namespaces which will have a
lot of dependant objects.

To limit the amount of queries performed, we can use `BatchLoader`.

## Testing

_full stack_ tests for a graphql query or mutation live in
`spec/requests/api/graphql`.

When adding a query, the `a working graphql query` shared example can
be used to test if the query renders valid results.

Using the `GraphqlHelpers#all_graphql_fields_for`-helper, a query
including all available fields can be constructed. This makes it easy
to add a test rendering all possible fields for a query.

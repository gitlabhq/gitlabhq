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

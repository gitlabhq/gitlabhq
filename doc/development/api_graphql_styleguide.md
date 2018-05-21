# GraphQL API

## Authentication

Authentication happens through the `GrapqlController`, right now this
uses the same authentication as the rails application. So the session
can be shared.

It is also possible to add a `private_token` to the querystring, or
add a `HTTP_PRIVATE_TOKEN` header.

### Authorization

Fields can be authorized using the same abilities used in the rails
app. This can be done using the `authorize` helper:

```ruby
Types::QueryType = GraphQL::ObjectType.define do
  name 'Query'

  field :project, Types::ProjectType do
    argument :full_path, !types.ID do
      description 'The full path of the project, e.g., "gitlab-org/gitlab-ce"'
    end

    authorize :read_project

    resolve Loaders::FullPathLoader[:project]
  end
end
```

The object found by the resolve call is used for authorization.


## Types

When exposing a model through the GraphQL API, we do so by creating a
new type in `app/graphql/types`.

When exposing properties in a type, make sure to keep the logic inside
the definition as minimal as possible. Instead, consider moving any
logic into a presenter:

```ruby
Types::MergeRequestType = GraphQL::ObjectType.define do
  present_using MergeRequestPresenter

  name 'MergeRequest'
end
```

An existing presenter could be used, but it is also possible to create
a new presenter specifically for GraphQL.

The presenter is initialized using the object resolved by a field, and
the context.

## Testing

_full stack_ tests for a graphql query or mutation live in
`spec/requests/graphql`.

When adding a query, the `a working graphql query` shared example can
be used to test the query, it expects a valid `query` to be available
in the spec.

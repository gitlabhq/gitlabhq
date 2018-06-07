module Types
  class BaseField < GraphQL::Schema::Field
    prepend Gitlab::Graphql::Authorize
  end
end

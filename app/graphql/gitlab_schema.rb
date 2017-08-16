Gitlab::Graphql::Authorize.register!

GitlabSchema = GraphQL::Schema.define do
  use GraphQL::Batch

  enable_preloading
  enable_authorization

  mutation(Types::MutationType)
  query(Types::QueryType)
end

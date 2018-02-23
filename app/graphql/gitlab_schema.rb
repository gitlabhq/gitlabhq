Gitlab::Graphql::Authorize.register!

GitlabSchema = GraphQL::Schema.define do
  use BatchLoader::GraphQL

  enable_preloading
  enable_authorization

  mutation(Types::MutationType)
  query(Types::QueryType)
end

Gitlab::Graphql::Authorize.register!
Gitlab::Graphql::Present.register!

GitlabSchema = GraphQL::Schema.define do
  use BatchLoader::GraphQL

  enable_preloading
  enable_authorization
  enable_presenting

  query(Types::QueryType)
end

class GitlabSchema < GraphQL::Schema
  use BatchLoader::GraphQL
  use Gitlab::Graphql::Authorize
  use Gitlab::Graphql::Present

  query(Types::QueryType)
  # mutation(Types::MutationType)
end

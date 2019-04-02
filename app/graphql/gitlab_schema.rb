# frozen_string_literal: true

class GitlabSchema < GraphQL::Schema
  use BatchLoader::GraphQL
  use Gitlab::Graphql::Authorize
  use Gitlab::Graphql::Present
  use Gitlab::Graphql::Connections
  use Gitlab::Graphql::Tracing

  query(Types::QueryType)

  default_max_page_size 100
  mutation(Types::MutationType)
end

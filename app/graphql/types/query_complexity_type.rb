# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class QueryComplexityType < ::Types::BaseObject
    graphql_name 'QueryComplexity'

    ANALYZER = GraphQL::Analysis::AST::QueryComplexity

    alias_method :query, :object

    field :limit, GraphQL::Types::Int,
      null: true,
      method: :max_complexity,
      see: {
        'GitLab documentation on this limit' =>
          'https://docs.gitlab.com/ee/api/graphql/index.html#max-query-complexity'
      },
      description: 'GraphQL query complexity limit.'

    field :score, GraphQL::Types::Int,
      null: true,
      description: 'GraphQL query complexity score.'

    def score
      ::GraphQL::Analysis::AST.analyze_query(query, [ANALYZER]).first
    end
  end
  # rubocop: enable Graphql/AuthorizeTypes
end

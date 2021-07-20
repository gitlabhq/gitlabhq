# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class QueryComplexityType < ::Types::BaseObject
    ANALYZER = GraphQL::Analysis::QueryComplexity.new { |_query, complexity| complexity }

    graphql_name 'QueryComplexity'

    alias_method :query, :object

    field :limit, GraphQL::INT_TYPE,
          null: true,
          method: :max_complexity,
          see: {
            'GitLab documentation on this limit' =>
              'https://docs.gitlab.com/ee/api/graphql/index.html#max-query-complexity'
          },
          description: 'GraphQL query complexity limit.'

    field :score, GraphQL::INT_TYPE,
          null: true,
          description: 'GraphQL query complexity score.'

    def score
      ::GraphQL::Analysis.analyze_query(query, [ANALYZER]).first
    end
  end
  # rubocop: enable Graphql/AuthorizeTypes
end

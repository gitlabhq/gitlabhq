# frozen_string_literal: true

module Types
  module Security
    module CodequalityReportsComparer
      # rubocop: disable Graphql/AuthorizeTypes -- The resolver authorizes the request
      class SummaryType < BaseObject
        graphql_name 'CodequalityReportsComparerReportSummary'

        description 'Represents a summary of the compared codequality report.'

        field :total,
          type: GraphQL::Types::Int,
          null: true,
          description: 'Total count of code quality degradations.'

        field :resolved,
          type: GraphQL::Types::Int,
          null: true,
          description: 'Count of resolved code quality degradations.'

        field :errored,
          type: GraphQL::Types::Int,
          null: true,
          description: 'Count of code quality errors.'
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end

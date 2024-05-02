# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  # Types that use DiffStatsType should have their own authorization
  class DiffStatsSummaryType < BaseObject
    graphql_name 'DiffStatsSummary'

    description 'Aggregated summary of changes'

    field :additions, GraphQL::Types::Int, null: false,
      description: 'Number of lines added.'
    field :changes, GraphQL::Types::Int, null: false,
      description: 'Number of lines changed.'
    field :deletions, GraphQL::Types::Int, null: false,
      description: 'Number of lines deleted.'
    field :file_count, GraphQL::Types::Int, null: false,
      description: 'Number of files changed.'

    def changes
      object[:additions] + object[:deletions]
    end
  end
  # rubocop: enable Graphql/AuthorizeTypes
end

# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  # Types that use DiffStatsType should have their own authorization
  class DiffStatsType < BaseObject
    graphql_name 'DiffStats'

    description 'Changes to a single file'

    field :path, GraphQL::STRING_TYPE, null: false,
          description: 'File path, relative to repository root.'
    field :additions, GraphQL::INT_TYPE, null: false,
          description: 'Number of lines added to this file.'
    field :deletions, GraphQL::INT_TYPE, null: false,
          description: 'Number of lines deleted from this file.'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end

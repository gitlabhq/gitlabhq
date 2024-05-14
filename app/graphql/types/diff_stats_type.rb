# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  # Types that use DiffStatsType should have their own authorization
  class DiffStatsType < BaseObject
    graphql_name 'DiffStats'

    description 'Changes to a single file'

    field :additions, GraphQL::Types::Int, null: false,
      description: 'Number of lines added to this file.'
    field :deletions, GraphQL::Types::Int, null: false,
      description: 'Number of lines deleted from this file.'
    field :path, GraphQL::Types::String, null: false,
      description: 'File path, relative to repository root.'

    def path
      object.path.dup.force_encoding('UTF-8')
    end
  end
  # rubocop: enable Graphql/AuthorizeTypes
end

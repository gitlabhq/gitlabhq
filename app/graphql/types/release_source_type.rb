# frozen_string_literal: true

module Types
  class ReleaseSourceType < BaseObject
    graphql_name 'ReleaseSource'

    authorize :read_release_sources

    field :format, GraphQL::STRING_TYPE, null: true,
          description: 'Format of the source'
    field :url, GraphQL::STRING_TYPE, null: true,
          description: 'Download URL of the source'
  end
end

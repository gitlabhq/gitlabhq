# frozen_string_literal: true

module Types
  class MetadataType < ::Types::BaseObject
    graphql_name 'Metadata'

    field :version, GraphQL::STRING_TYPE, null: false
    field :revision, GraphQL::STRING_TYPE, null: false
  end
end

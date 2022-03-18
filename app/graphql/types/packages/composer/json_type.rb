# frozen_string_literal: true

module Types
  module Packages
    module Composer
      # rubocop: disable Graphql/AuthorizeTypes
      class JsonType < BaseObject
        graphql_name 'PackageComposerJsonType'
        description 'Represents a composer JSON file'

        field :license, GraphQL::Types::String, null: true, description: 'License set in the Composer JSON file.'
        field :name, GraphQL::Types::String, null: true, description: 'Name set in the Composer JSON file.'
        field :type, GraphQL::Types::String, null: true, description: 'Type set in the Composer JSON file.'
        field :version, GraphQL::Types::String, null: true, description: 'Version set in the Composer JSON file.'
      end
    end
  end
end

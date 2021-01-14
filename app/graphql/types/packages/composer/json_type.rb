# frozen_string_literal: true

module Types
  module Packages
    module Composer
      # rubocop: disable Graphql/AuthorizeTypes
      class JsonType < BaseObject
        graphql_name 'PackageComposerJsonType'
        description 'Represents a composer JSON file'

        field :name, GraphQL::STRING_TYPE, null: true, description: 'The name set in the Composer JSON file.'
        field :type, GraphQL::STRING_TYPE, null: true, description: 'The type set in the Composer JSON file.'
        field :license, GraphQL::STRING_TYPE, null: true, description: 'The license set in the Composer JSON file.'
        field :version, GraphQL::STRING_TYPE, null: true, description: 'The version set in the Composer JSON file.'
      end
    end
  end
end

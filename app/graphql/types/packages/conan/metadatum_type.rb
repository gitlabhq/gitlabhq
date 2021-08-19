# frozen_string_literal: true

module Types
  module Packages
    module Conan
      class MetadatumType < BaseObject
        graphql_name 'ConanMetadata'
        description 'Conan metadata'

        authorize :read_package

        field :id, ::Types::GlobalIDType[::Packages::Conan::Metadatum], null: false, description: 'ID of the metadatum.'
        field :created_at, Types::TimeType, null: false, description: 'Date of creation.'
        field :updated_at, Types::TimeType, null: false, description: 'Date of most recent update.'
        field :package_username, GraphQL::Types::String, null: false, description: 'Username of the Conan package.'
        field :package_channel, GraphQL::Types::String, null: false, description: 'Channel of the Conan package.'
        field :recipe, GraphQL::Types::String, null: false, description: 'Recipe of the Conan package.'
        field :recipe_path, GraphQL::Types::String, null: false, description: 'Recipe path of the Conan package.'
      end
    end
  end
end

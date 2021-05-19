# frozen_string_literal: true

module Types
  module Packages
    module Maven
      class MetadatumType < BaseObject
        graphql_name 'MavenMetadata'
        description 'Maven metadata'

        authorize :read_package

        field :id, ::Types::GlobalIDType[::Packages::Maven::Metadatum], null: false, description: 'ID of the metadatum.'
        field :created_at, Types::TimeType, null: false, description: 'Date of creation.'
        field :updated_at, Types::TimeType, null: false, description: 'Date of most recent update.'
        field :path, GraphQL::STRING_TYPE, null: false, description: 'Path of the Maven package.'
        field :app_group, GraphQL::STRING_TYPE, null: false, description: 'App group of the Maven package.'
        field :app_version, GraphQL::STRING_TYPE, null: true, description: 'App version of the Maven package.'
        field :app_name, GraphQL::STRING_TYPE, null: false, description: 'App name of the Maven package.'
      end
    end
  end
end

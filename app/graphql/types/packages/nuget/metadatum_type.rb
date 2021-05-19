# frozen_string_literal: true

module Types
  module Packages
    module Nuget
      class MetadatumType < BaseObject
        graphql_name 'NugetMetadata'
        description 'Nuget metadata'

        authorize :read_package

        field :id, ::Types::GlobalIDType[::Packages::Nuget::Metadatum], null: false, description: 'ID of the metadatum.'
        field :license_url, GraphQL::STRING_TYPE, null: false, description: 'License URL of the Nuget package.'
        field :project_url, GraphQL::STRING_TYPE, null: false, description: 'Project URL of the Nuget package.'
        field :icon_url, GraphQL::STRING_TYPE, null: false, description: 'Icon URL of the Nuget package.'
      end
    end
  end
end

# frozen_string_literal: true

module Types
  module Packages
    module Nuget
      class DependencyLinkMetadatumType < BaseObject
        graphql_name 'NugetDependencyLinkMetadata'
        description 'Nuget dependency link metadata'

        authorize :read_package

        field :id, ::Types::GlobalIDType[::Packages::Nuget::DependencyLinkMetadatum], null: false,
          description: 'ID of the metadatum.'
        field :target_framework, GraphQL::Types::String, null: false,
          description: 'Target framework of the dependency link package.'
      end
    end
  end
end

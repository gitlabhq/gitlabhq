# frozen_string_literal: true

module Types
  module Packages
    module TerraformModule
      module Metadatum
        class RootType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- Already authorized in parent MetadatumType
          graphql_name 'TerraformModuleMetadataRoot'
          description 'Metadata for Terraform root module'

          implements SharedFieldsInterface

          field :dependencies, Types::Packages::TerraformModule::Metadatum::DependenciesType, null: true,
            description: 'Dependencies of the module.'
          field :resources, [GraphQL::Types::String], null: true, description: 'Resources of the module.'
        end
      end
    end
  end
end

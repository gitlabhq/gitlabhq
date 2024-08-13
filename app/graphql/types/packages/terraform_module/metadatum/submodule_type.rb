# frozen_string_literal: true

module Types
  module Packages
    module TerraformModule
      module Metadatum
        class SubmoduleType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- Already authorized in parent MetadatumType
          graphql_name 'TerraformModuleMetadataSubmodule'
          description 'Terraform module metadata submodule'

          implements SharedFieldsInterface

          field :dependencies, Types::Packages::TerraformModule::Metadatum::DependenciesType, null: true,
            description: 'Dependencies of the submodule.'
          field :name, GraphQL::Types::String, null: false, description: 'Name of the submodule.'
          field :resources, [GraphQL::Types::String], null: true, description: 'Resources of the submodule.'
        end
      end
    end
  end
end

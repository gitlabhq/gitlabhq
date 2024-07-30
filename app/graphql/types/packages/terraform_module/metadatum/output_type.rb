# frozen_string_literal: true

module Types
  module Packages
    module TerraformModule
      module Metadatum
        class OutputType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- Already authorized in parent MetadatumType
          graphql_name 'TerraformModuleMetadataOutput'
          description 'Terraform module metadata output'

          field :description, GraphQL::Types::String, null: true, description: 'Description of the output field.'
          field :name, GraphQL::Types::String, null: false, description: 'Name of the output field.'
        end
      end
    end
  end
end

# frozen_string_literal: true

module Types
  module Packages
    module TerraformModule
      module Metadatum
        class ExampleType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- Already authorized in parent MetadatumType
          graphql_name 'TerraformModuleMetadataExample'
          description 'Terraform module metadata example'

          implements SharedFieldsInterface

          field :name, GraphQL::Types::String, null: false, description: 'Name of the example.'
        end
      end
    end
  end
end

# frozen_string_literal: true

module Types
  module Packages
    module TerraformModule
      module Metadatum
        # This is not a GraphQL input type, but a terraform module input variables type: https://developer.hashicorp.com/terraform/language/values/variables
        class InputType < BaseObject
          graphql_name 'TerraformModuleMetadataInput'
          description 'Terraform module metadata input type'

          field :default, GraphQL::Types::String, null: true, description: 'Default value of the input.'
          field :description, GraphQL::Types::String, null: true, description: 'Description of the input.'
          field :name, GraphQL::Types::String, null: false, description: 'Name of the input.'
          field :type, GraphQL::Types::String, null: false, description: 'Type of the input.'
        end
      end
    end
  end
end

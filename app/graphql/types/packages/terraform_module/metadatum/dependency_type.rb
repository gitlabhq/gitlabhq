# frozen_string_literal: true

module Types
  module Packages
    module TerraformModule
      module Metadatum
        class DependencyType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- Already authorized in parent
          graphql_name 'TerraformModuleMetadataDependency'
          description 'Terraform module metadata dependency'

          field :name, GraphQL::Types::String, null: false, description: 'Name of the dependency.'
          field :source, GraphQL::Types::String, null: true, description: 'Source of the dependency.'
          field :version, GraphQL::Types::String, null: true, description: 'Version of the dependency.'
        end
      end
    end
  end
end

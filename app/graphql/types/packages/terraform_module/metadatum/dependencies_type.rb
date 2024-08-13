# frozen_string_literal: true

module Types
  module Packages
    module TerraformModule
      module Metadatum
        class DependenciesType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- Already authorized in parent
          graphql_name 'TerraformModuleMetadataDependencies'
          description 'Terraform module metadata dependencies'

          field :modules, [Types::Packages::TerraformModule::Metadatum::DependencyType], null: true,
            description: 'Modules of the module.'
          field :providers, [Types::Packages::TerraformModule::Metadatum::DependencyType], null: true,
            description: 'Providers of the module.'
        end
      end
    end
  end
end

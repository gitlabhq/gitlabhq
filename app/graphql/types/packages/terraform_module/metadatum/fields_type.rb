# frozen_string_literal: true

module Types
  module Packages
    module TerraformModule
      module Metadatum
        class FieldsType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- This type is used for package metadata
          graphql_name 'TerraformModuleMetadataFields'
          description 'Terraform module metadata fields type'

          field :examples, [Types::Packages::TerraformModule::Metadatum::ExampleType], null: true,
            description: 'Examples of the module.'
          field :root, Types::Packages::TerraformModule::Metadatum::RootType, null: false,
            description: 'Root module.'
          field :submodules, [Types::Packages::TerraformModule::Metadatum::SubmoduleType], null: true,
            description: 'Submodules of the module.'

          def submodules
            hash_to_arr(object['submodules'])
          end

          def examples
            hash_to_arr(object['examples'])
          end

          private

          def hash_to_arr(hash)
            return unless hash

            hash.map { |name, details| { name: name }.merge(details) }
          end
        end
      end
    end
  end
end

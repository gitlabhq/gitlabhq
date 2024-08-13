# frozen_string_literal: true

module Types
  module Packages
    module TerraformModule
      module Metadatum
        module SharedFieldsInterface
          include ::Types::BaseInterface
          prepend Gitlab::Graphql::MarkdownField

          graphql_name 'TerraformModuleMetadataSharedFields'

          field :inputs, [Types::Packages::TerraformModule::Metadatum::InputType], null: true,
            description: 'Inputs of the module.'
          field :outputs, [Types::Packages::TerraformModule::Metadatum::OutputType], null: true,
            description: 'Outputs of the module.'
          field :readme, GraphQL::Types::String, null: true, description: 'Readme data.'

          markdown_field :readme_html, null: true

          def readme_html_resolver
            ::MarkupHelper.markdown(object['readme'], context.to_h.dup)
          end
        end
      end
    end
  end
end

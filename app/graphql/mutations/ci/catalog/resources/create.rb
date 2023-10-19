# frozen_string_literal: true

module Mutations
  module Ci
    module Catalog
      module Resources
        class Create < BaseMutation
          graphql_name 'CatalogResourcesCreate'

          argument :project_path, GraphQL::Types::ID,
            required: true,
            description: 'Project to convert to a catalog resource.'

          authorize :add_catalog_resource

          def resolve(project_path:)
            project = authorized_find!(project_path: project_path)
            response = ::Ci::Catalog::AddResourceService.new(project, current_user).execute

            errors = response.success? ? [] : [response.message]

            {
              errors: errors
            }
          end

          private

          def find_object(project_path:)
            Project.find_by_full_path(project_path)
          end
        end
      end
    end
  end
end

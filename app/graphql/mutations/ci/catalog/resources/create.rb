# frozen_string_literal: true

module Mutations
  module Ci
    module Catalog
      module Resources
        class Create < Base
          graphql_name 'CatalogResourcesCreate'

          authorize :add_catalog_resource
          authorize_granular_token permissions: :create_catalog_resource,
            boundary_argument: :project_path, boundary_type: :project

          def resolve(project_path:)
            project = authorized_find!(project_path: project_path)
            response = ::Ci::Catalog::Resources::CreateService.new(project, current_user).execute

            errors = response.success? ? [] : [response.message]

            {
              errors: errors
            }
          end
        end
      end
    end
  end
end

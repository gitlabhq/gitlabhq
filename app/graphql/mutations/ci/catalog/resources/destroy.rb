# frozen_string_literal: true

module Mutations
  module Ci
    module Catalog
      module Resources
        class Destroy < Base
          graphql_name 'CatalogResourcesDestroy'

          authorize :add_catalog_resource

          def resolve(project_path:)
            project = authorized_find!(project_path: project_path)
            catalog_resource = project.catalog_resource

            response = ::Ci::Catalog::Resources::DestroyService.new(project, current_user).execute(catalog_resource)

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

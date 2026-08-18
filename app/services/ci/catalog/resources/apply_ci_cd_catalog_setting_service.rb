# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      # Applies the `cicd_catalog_enabled` setting to a project by creating or
      # destroying its `Ci::Catalog::Resource` record. This keeps the catalog
      # domain logic out of the API layer.
      class ApplyCiCdCatalogSettingService
        DESCRIPTION_REQUIRED_MESSAGE =
          'To set the project as a catalog resource, the project must have a description.'

        attr_reader :project, :current_user, :should_enable

        def initialize(project, current_user, enabled:)
          @project = project
          @current_user = current_user
          @should_enable = enabled
        end

        def execute
          return ServiceResponse.success if should_enable.nil?

          catalog_resource = project.catalog_resource
          return ServiceResponse.success if catalog_resource.present? == should_enable

          response =
            if should_enable
              enable
            else
              ::Ci::Catalog::Resources::DestroyService.new(project, current_user).execute(catalog_resource)
            end

          return response if response.error?

          project.association(:catalog_resource).reset

          ServiceResponse.success
        end

        private

        def enable
          # A description is required for a catalog resource to be listed correctly
          # in the CI/CD Catalog. The UI enforces this by disabling the toggle; mirror
          # that here so the setting cannot be enabled on a project without one.
          return ServiceResponse.error(message: DESCRIPTION_REQUIRED_MESSAGE) if project.description.blank?

          ::Ci::Catalog::Resources::CreateService.new(project, current_user).execute
        end
      end
    end
  end
end

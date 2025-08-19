# frozen_string_literal: true

module Projects
  module Packages
    class InfrastructureRegistryController < Projects::ApplicationController
      include PackagesAccess

      feature_category :package_registry
      urgency :low

      def show
        @package = ::Packages::TerraformModule::Package
                     .preload_pipelines_with_user_project_namespace_route
                     .for_projects(project)
                     .find(params.permit(:id)[:id])
      end
    end
  end
end

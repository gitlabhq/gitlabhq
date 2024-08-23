# frozen_string_literal: true

module Projects
  module Packages
    class InfrastructureRegistryController < Projects::ApplicationController
      include PackagesAccess

      feature_category :package_registry
      urgency :low

      def show
        @package = project.packages.find(params.permit(:id)[:id])
      end
    end
  end
end

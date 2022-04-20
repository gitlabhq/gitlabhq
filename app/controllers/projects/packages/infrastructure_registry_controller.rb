# frozen_string_literal: true

module Projects
  module Packages
    class InfrastructureRegistryController < Projects::ApplicationController
      include PackagesAccess

      feature_category :infrastructure_as_code

      def show
        @package = project.packages.find(params[:id])
      end
    end
  end
end

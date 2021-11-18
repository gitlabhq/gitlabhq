# frozen_string_literal: true

module Projects
  module Packages
    class PackagesController < Projects::ApplicationController
      include PackagesAccess

      feature_category :package_registry

      def show
        @package = project.packages.find(params[:id])
      end
    end
  end
end

# frozen_string_literal: true

module Projects
  module Packages
    class PackagesController < Projects::ApplicationController
      include PackagesAccess

      feature_category :package_registry

      before_action do
        push_frontend_feature_flag(:package_list_apollo, default_enabled: :yaml)
      end

      def show
        @package = project.packages.find(params[:id])
      end
    end
  end
end

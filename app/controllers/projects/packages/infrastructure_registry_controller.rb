# frozen_string_literal: true

module Projects
  module Packages
    class InfrastructureRegistryController < Projects::ApplicationController
      before_action :verify_feature_enabled!
      feature_category :infrastructure_as_code

      def show
        @package = project.packages.find(params[:id])
        @package_files = @package.package_files.recent
      end

      private

      def verify_feature_enabled!
        render_404 unless Feature.enabled?(:infrastructure_registry_page, default_enabled: :yaml)
      end
    end
  end
end

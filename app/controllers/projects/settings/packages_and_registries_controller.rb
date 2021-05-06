# frozen_string_literal: true

module Projects
  module Settings
    class PackagesAndRegistriesController < Projects::ApplicationController
      layout 'project_settings'

      before_action :authorize_admin_project!
      before_action :packages_and_registries_settings_enabled!

      feature_category :package_registry

      def show
      end

      private

      def packages_and_registries_settings_enabled!
        render_404 unless settings_packages_and_registries_enabled?(project)
      end
    end
  end
end

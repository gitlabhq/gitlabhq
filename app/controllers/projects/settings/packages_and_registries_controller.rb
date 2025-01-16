# frozen_string_literal: true

module Projects
  module Settings
    class PackagesAndRegistriesController < Projects::ApplicationController
      layout 'project_settings'

      before_action :authorize_admin_project!
      before_action :packages_and_registries_settings_enabled!
      before_action :set_feature_flag_packages_protected_packages, only: :show
      before_action :set_feature_flag_container_registry_protected_tags, only: :show

      feature_category :package_registry
      urgency :low

      def show; end

      def cleanup_tags
        registry_settings_enabled!

        @hide_search_settings = true
      end

      private

      def packages_and_registries_settings_enabled!
        render_404 unless can?(current_user, :view_package_registry_project_settings, project)
      end

      def registry_settings_enabled!
        render_404 unless Gitlab.config.registry.enabled &&
          can?(current_user, :admin_container_image, project)
      end

      def set_feature_flag_packages_protected_packages
        push_frontend_feature_flag(:packages_protected_packages_conan, project)
      end

      def set_feature_flag_container_registry_protected_tags
        push_frontend_feature_flag(:container_registry_protected_tags, project)
      end
    end
  end
end

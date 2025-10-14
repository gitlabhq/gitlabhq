# frozen_string_literal: true

module Groups
  module Settings
    class PackagesAndRegistriesController < Groups::ApplicationController
      layout 'group_settings'
      before_action :authorize_admin_group!
      before_action :verify_packages_enabled!

      before_action do
        push_frontend_feature_flag(:maven_central_request_forwarding, group)
        push_frontend_ability(ability: :admin_dependency_proxy, resource: group, user: current_user)
      end

      feature_category :package_registry
      urgency :low

      def show; end

      private

      def verify_packages_enabled!
        render_404 unless group.packages_feature_enabled?
      end
    end
  end
end

Groups::Settings::PackagesAndRegistriesController.prepend_mod

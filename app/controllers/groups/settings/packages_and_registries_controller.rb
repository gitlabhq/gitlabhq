# frozen_string_literal: true

module Groups
  module Settings
    class PackagesAndRegistriesController < Groups::ApplicationController
      layout 'group_settings'
      before_action :authorize_admin_group!
      before_action :verify_packages_enabled!

      feature_category :package_registry

      def show
      end

      private

      def verify_packages_enabled!
        render_404 unless group.packages_feature_enabled?
      end
    end
  end
end

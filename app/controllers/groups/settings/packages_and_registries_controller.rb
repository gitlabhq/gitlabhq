# frozen_string_literal: true

module Groups
  module Settings
    class PackagesAndRegistriesController < Groups::ApplicationController
      before_action :authorize_admin_group!

      feature_category :package_registry

      def index
      end
    end
  end
end

# frozen_string_literal: true

module Projects
  module Packages
    class PackagesController < Projects::ApplicationController
      include PackagesAccess

      feature_category :package_registry
      urgency :low

      before_action :set_feature_flag_packages_protected_packages, only: :index

      def index; end

      # The show action renders index to allow frontend routing to work on page refresh
      def show
        render :index
      end

      private

      def set_feature_flag_packages_protected_packages
        push_frontend_feature_flag(:packages_protected_packages, project)
      end
    end
  end
end

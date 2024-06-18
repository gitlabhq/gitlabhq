# frozen_string_literal: true

module Groups
  class PackagesController < Groups::ApplicationController
    before_action :verify_packages_enabled!

    feature_category :package_registry
    urgency :low

    before_action :set_feature_flag_packages_protected_packages, only: :show

    # The show action renders index to allow frontend routing to work on page refresh
    def show
      render :index
    end

    private

    def verify_packages_enabled!
      render_404 unless group.packages_feature_enabled?
    end

    def set_feature_flag_packages_protected_packages
      push_frontend_feature_flag(:packages_protected_packages, group)
    end
  end
end

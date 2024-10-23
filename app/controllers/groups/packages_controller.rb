# frozen_string_literal: true

module Groups
  class PackagesController < Groups::ApplicationController
    before_action :verify_packages_enabled!

    feature_category :package_registry
    urgency :low

    def index; end

    # The show action renders index to allow frontend routing to work on page refresh
    def show
      render :index
    end

    private

    def verify_packages_enabled!
      render_404 unless group.packages_feature_enabled?
    end
  end
end

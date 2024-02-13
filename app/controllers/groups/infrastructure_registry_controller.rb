# frozen_string_literal: true

module Groups
  class InfrastructureRegistryController < Groups::ApplicationController
    before_action :verify_packages_enabled!

    feature_category :package_registry
    urgency :low

    private

    def verify_packages_enabled!
      render_404 unless group.packages_feature_enabled?
    end
  end
end

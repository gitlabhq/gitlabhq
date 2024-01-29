# frozen_string_literal: true

module Groups
  class InfrastructureRegistryController < Groups::ApplicationController
    before_action :verify_packages_enabled!

    feature_category :package_registry
    urgency :low

    private

    def verify_packages_enabled!
      unless group.packages_feature_enabled? &&
          Feature.enabled?(:group_level_infrastructure_registry, group.root_ancestor, type: :gitlab_com_derisk)
        render_404
      end
    end
  end
end

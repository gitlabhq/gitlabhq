# frozen_string_literal: true

module Groups
  module Settings
    class IntegrationsController < Groups::ApplicationController
      include IntegrationsActions

      before_action :authorize_admin_group!

      private

      # TODO: Make this compatible with group-level integration
      # https://gitlab.com/groups/gitlab-org/-/epics/2543
      def find_or_initialize_integration(name)
        Project.first.find_or_initialize_service(name)
      end

      def integrations_enabled?
        Feature.enabled?(:group_level_integrations, group)
      end

      def scoped_edit_integration_path(integration)
        edit_group_settings_integration_path(group, integration)
      end
    end
  end
end

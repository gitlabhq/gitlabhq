# frozen_string_literal: true

module Groups
  module Settings
    class IntegrationsController < Groups::ApplicationController
      include IntegrationsActions

      before_action :authorize_admin_group!

      private

      def integrations_enabled?
        Feature.enabled?(:group_level_integrations, group)
      end

      def scoped_edit_integration_path(integration)
        edit_group_settings_integration_path(group, integration)
      end
    end
  end
end

# frozen_string_literal: true

module Groups
  module Settings
    class IntegrationsController < Groups::ApplicationController
      include IntegrationsActions

      before_action :authorize_admin_group!

      feature_category :integrations

      layout 'group_settings'

      def index
        @integrations = Integration.find_or_initialize_all_non_project_specific(Integration.for_group(group)).sort_by(&:title)
      end

      def edit
        @default_integration = Integration.default_integration(integration.type, group)

        super
      end

      private

      def find_or_initialize_non_project_specific_integration(name)
        Integration.find_or_initialize_non_project_specific_integration(name, group_id: group.id)
      end

      def scoped_edit_integration_path(integration)
        edit_group_settings_integration_path(group, integration)
      end
    end
  end
end

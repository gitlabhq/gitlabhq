# frozen_string_literal: true

module Groups
  module Settings
    class IntegrationsController < Groups::ApplicationController
      include IntegrationsActions

      before_action :authorize_admin_group!

      feature_category :integrations

      def index
        @integrations = Service.find_or_initialize_all_non_project_specific(Service.for_group(group)).sort_by(&:title)
      end

      def edit
        @default_integration = Service.default_integration(integration.type, group)

        super
      end

      private

      def find_or_initialize_non_project_specific_integration(name)
        Service.find_or_initialize_non_project_specific_integration(name, group_id: group.id)
      end

      def integrations_enabled?
        Feature.enabled?(:group_level_integrations, group, default_enabled: true)
      end

      def scoped_edit_integration_path(integration)
        edit_group_settings_integration_path(group, integration)
      end
    end
  end
end

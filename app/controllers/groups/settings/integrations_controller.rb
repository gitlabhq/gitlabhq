# frozen_string_literal: true

module Groups
  module Settings
    class IntegrationsController < Groups::ApplicationController
      include ::Integrations::Actions

      before_action :authorize_admin_integrations!

      feature_category :integrations

      layout 'group_settings'

      def index
        @integrations = Integration
          .find_or_initialize_all_non_project_specific(Integration.for_group(group))
          .sort_by { |int| int.title.downcase }
      end

      def edit
        @default_integration = Integration.default_integration(integration.type, group)

        super
      end

      private

      def find_or_initialize_non_project_specific_integration(name)
        Integration.find_or_initialize_non_project_specific_integration(name, group_id: group.id)
      end
    end
  end
end

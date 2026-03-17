# frozen_string_literal: true

module Groups
  module Settings
    class IntegrationsController < Groups::ApplicationController
      include ::Integrations::Actions

      before_action :authorize_admin_integrations!

      before_action only: [:edit] do
        push_frontend_feature_flag(:finer_filters_for_integrations, group)
      end

      feature_category :integrations

      layout 'group_settings'

      def index
        @integrations = Integration.find_or_initialize_all_non_project_specific(Integration.for_group(group))

        @integrations = experiment(:ordered_integrations, actor: current_user) do |e|
          e.control { @integrations.sort_by { |integration| integration.title.downcase } }
          e.candidate do
            @integrations.sort_by do |integration|
              ranking = Integration::INTEGRATION_POPULARITY_RANKING.index(integration.type)
              [ranking || Float::INFINITY, integration.title.downcase]
            end
          end
        end.run
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

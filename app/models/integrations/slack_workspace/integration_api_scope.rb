# frozen_string_literal: true

module Integrations
  module SlackWorkspace
    class IntegrationApiScope < ApplicationRecord
      self.table_name = 'slack_integrations_scopes'

      belongs_to :slack_api_scope, class_name: 'Integrations::SlackWorkspace::ApiScope'
      belongs_to :slack_integration
      belongs_to :project, optional: true
      belongs_to :group, optional: true
      belongs_to :organization, class_name: 'Organizations::Organization', optional: true

      before_validation :ensure_sharding_key

      validates_with ExactlyOnePresentValidator, fields: %i[project group organization]

      # Efficient scope propagation
      def self.update_scopes(integrations, scopes)
        return if integrations.empty?

        scope_ids = scopes.pluck(:id)

        attrs = scope_ids.flat_map do |scope_id|
          integrations.map do |integration|
            {
              slack_integration_id: integration.id,
              slack_api_scope_id: scope_id,
              organization_id: integration.organization_id,
              group_id: integration.group_id,
              project_id: integration.project_id
            }
          end
        end

        # We don't know which ones to preserve - so just delete them all in a single query
        transaction do
          where(slack_integration_id: integrations.pluck_primary_key).delete_all
          insert_all(attrs)
        end
      end

      private

      def ensure_sharding_key
        # TODO: get sharding key directly from SlackIntegration
        # https://gitlab.com/gitlab-org/gitlab/-/work_items/582748
        parent_integration = slack_integration.integration

        self.project_id = parent_integration.project_id
        self.group_id = parent_integration.group_id
        self.organization_id = parent_integration.organization_id
      end
    end
  end
end

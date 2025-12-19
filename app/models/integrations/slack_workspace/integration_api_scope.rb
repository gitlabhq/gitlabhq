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
      def self.update_scopes(slack_integrations, scopes)
        return if slack_integrations.empty?

        slack_integrations = slack_integrations.preload_integration_organization
        organization_ids_by_integration = slack_integrations.each_with_object({}) do |slack_integration, result|
          result[slack_integration.id] = slack_integration.integration.organization_id_from_parent
        end

        scopes_by_organization = ApiScope.find_or_initialize_by_names_and_organizations(
          scopes.pluck(:name),
          organization_ids_by_integration.values.uniq
        )

        attrs = slack_integrations.flat_map do |slack_integration|
          organization_id = organization_ids_by_integration[slack_integration.id]
          scopes_by_organization[organization_id].map do |scope|
            {
              slack_integration_id: slack_integration.id,
              slack_api_scope_id: scope.id,
              organization_id: slack_integration.integration.organization_id,
              group_id: slack_integration.integration.group_id,
              project_id: slack_integration.integration.project_id
            }
          end
        end

        # We don't know which ones to preserve - so just delete them all in a single query
        transaction do
          where(slack_integration_id: slack_integrations.pluck_primary_key).delete_all
          upsert_all(attrs, on_duplicate: :skip)
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

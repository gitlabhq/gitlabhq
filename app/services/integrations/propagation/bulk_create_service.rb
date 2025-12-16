# frozen_string_literal: true

module Integrations
  module Propagation
    class BulkCreateService
      include BulkOperationHashes

      def initialize(integration, batch, association)
        @integration = integration
        @batch = batch.to_a
        @association = association
      end

      def execute
        Integration.transaction do
          inserted_ids = bulk_insert_integrations

          bulk_insert_data_fields(inserted_ids) if integration.data_fields_present?

          if integration.is_a?(GitlabSlackApplication) && integration.active?
            inserted_slack_ids = bulk_insert_slack_integrations(inserted_ids)
            bulk_insert_slack_integration_scopes(inserted_slack_ids)
          end
        end
      end

      private

      attr_reader :integration, :batch, :association

      def bulk_insert_integrations
        attributes = integration_hash(:create)

        items_to_insert = batch.map do |record|
          attributes.merge("#{association}_id" => record.id)
        end

        bulk_insert_new(Integration, items_to_insert)
      end

      def bulk_insert_data_fields(integration_ids)
        model = integration.data_fields.class
        integration_fk_name = model.reflections['integration'].foreign_key
        attributes = data_fields_hash(:create)

        items_to_insert = integration_ids.zip(batch).map do |integration_id, record|
          attributes.merge(
            integration_fk_name => integration_id,
            "#{association}_id" => record.id
          )
        end

        bulk_insert_new(model, items_to_insert)
      end

      def bulk_insert_slack_integrations(integration_ids)
        hash = integration.slack_integration.to_database_hash

        items_to_insert = integration_ids.zip(batch).map do |integration_id, record|
          hash.merge(
            'integration_id' => integration_id,
            'alias' => record.full_path,
            "#{association}_id" => record.id
          )
        end

        bulk_insert_new(SlackIntegration, items_to_insert)
      end

      def bulk_insert_slack_integration_scopes(inserted_slack_ids)
        scopes = integration.slack_integration.slack_api_scopes

        items_to_insert = scopes.flat_map do |scope|
          # TODO: Get sharding key values directly from insert query
          # https://gitlab.com/gitlab-org/gitlab/-/work_items/582748
          SlackIntegration.id_in(inserted_slack_ids).preloaded_integration.map do |slack_integration|
            {
              'slack_integration_id' => slack_integration.id,
              'slack_api_scope_id' => scope.id,
              'project_id' => slack_integration.integration.project_id,
              'group_id' => slack_integration.integration.group_id,
              'organization_id' => slack_integration.integration.organization_id
            }
          end
        end

        bulk_insert_new(SlackWorkspace::IntegrationApiScope, items_to_insert)
      end
    end
  end
end

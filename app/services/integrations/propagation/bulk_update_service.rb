# frozen_string_literal: true

module Integrations
  module Propagation
    class BulkUpdateService
      include BulkOperationHashes

      def initialize(integration, batch)
        @integration = integration
        @batch = batch
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def execute
        Integration.transaction do
          Integration.where(id: batch_ids).update_all(integration_hash(:update))

          if integration.data_fields_present?
            integration.data_fields.class.where(data_fields_foreign_key => batch_ids)
              .update_all(
                data_fields_hash(:update)
              )
          end

          if integration.is_a?(GitlabSlackApplication)
            if integration.active?
              bulk_update_slack_integrations
            else
              bulk_delete_slack_integrations
            end
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      attr_reader :integration, :batch

      # service_id or integration_id
      def data_fields_foreign_key
        integration.data_fields.class.reflections['integration'].foreign_key
      end

      def batch_ids
        @batch_ids ||=
          if batch.is_a?(ActiveRecord::Relation)
            batch.select(:id)
          else
            batch.map(&:id)
          end
      end

      def bulk_update_slack_integrations
        slack_integration_batch = SlackIntegration.by_integration(batch_ids)

        slack_integration_batch.update_all(
          integration.slack_integration.to_database_hash
        )

        Integrations::SlackWorkspace::IntegrationApiScope.update_scopes(
          slack_integration_batch.pluck_primary_key,
          integration.slack_integration.slack_api_scopes
        )
      end

      def bulk_delete_slack_integrations
        SlackIntegration.by_integration(batch_ids).delete_all
      end
    end
  end
end

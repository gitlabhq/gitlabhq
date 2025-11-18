# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSlackIntegrationsShardingKey < BatchedMigrationJob
      operation_name :backfill_slack_integrations_sharding_key
      feature_category :integrations

      def perform
        each_sub_batch do |sub_batch|
          records_to_update = sub_batch.where(project_id: nil, group_id: nil, organization_id: nil)

          connection.execute(update_sql(records_to_update))
        end
      end

      private

      def update_sql(sub_batch)
        <<~SQL
          UPDATE
            slack_integrations
          SET
            project_id = integrations.project_id,
            group_id = integrations.group_id,
            organization_id = integrations.organization_id
          FROM
            integrations
          WHERE
            integrations.id = slack_integrations.integration_id
          AND
            slack_integrations.id IN (#{sub_batch.select(:id).to_sql})
        SQL
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIssueTrackerDataShardingKey < BatchedMigrationJob
      operation_name :backfill_issue_tracker_data_sharding_key
      feature_category :integrations

      class Integration < ::ApplicationRecord
        self.table_name = 'integrations'
        self.inheritance_column = :_type_disabled
      end

      def perform
        each_sub_batch do |sub_batch|
          sub_batch = sub_batch.where(project_id: nil, group_id: nil, organization_id: nil)
          integration_ids = sub_batch.pluck(:integration_id)
          integrations = Integration.where(id: integration_ids).index_by(&:id)

          sub_batch.each do |record|
            integration = integrations[record.integration_id]

            next unless integration

            record.update(
              project_id: integration.project_id,
              group_id: integration.group_id,
              organization_id: integration.organization_id
            )
          end
        end
      end
    end
  end
end

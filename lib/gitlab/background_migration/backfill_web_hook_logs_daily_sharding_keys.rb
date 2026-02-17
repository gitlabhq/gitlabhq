# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillWebHookLogsDailyShardingKeys < BatchedMigrationJob
      cursor :id, :created_at
      operation_name :backfill_web_hook_logs_daily_sharding_keys
      feature_category :webhooks

      def perform
        each_sub_batch do |sub_batch|
          records_to_update = sub_batch.where(
            organization_id: nil,
            project_id: nil,
            group_id: nil
          )

          connection.execute(update_sql(records_to_update))
        end
      end

      private

      def update_sql(sub_batch)
        <<~SQL
          WITH filtered_ids AS MATERIALIZED (
            #{sub_batch.select(:id).to_sql}
          )
          UPDATE
            web_hook_logs_daily
          SET
            organization_id = web_hooks.organization_id,
            project_id = web_hooks.project_id,
            group_id = web_hooks.group_id
          FROM
            web_hooks
          WHERE
            web_hooks.id = web_hook_logs_daily.web_hook_id
          AND
            web_hook_logs_daily.id IN (SELECT id FROM filtered_ids)
        SQL
      end
    end
  end
end

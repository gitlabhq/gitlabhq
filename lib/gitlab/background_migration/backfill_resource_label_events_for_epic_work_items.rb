# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillResourceLabelEventsForEpicWorkItems < BatchedMigrationJob
      operation_name :backfill_resource_label_events_for_epic_work_items
      feature_category :portfolio_management
      tables_to_check_for_vacuum :resource_label_events

      RESOURCE_LABEL_EVENTS_BATCH_SIZE = 100

      def perform
        each_sub_batch do |sub_batch|
          backfill_resource_label_events(sub_batch)
        end
      end

      private

      def backfill_resource_label_events(sub_batch)
        loop do
          result = connection.execute(<<~SQL)
            WITH resource_label_events_for_update AS MATERIALIZED (
              SELECT
                resource_label_events.id AS id,
                epics.issue_id AS issue_id
              FROM resource_label_events
              INNER JOIN epics ON epics.id = resource_label_events.epic_id
              WHERE resource_label_events.epic_id IN (#{sub_batch.select(:id).to_sql})
              LIMIT #{RESOURCE_LABEL_EVENTS_BATCH_SIZE}
            )
            UPDATE resource_label_events
            SET issue_id = resource_label_events_for_update.issue_id, epic_id = NULL
            FROM resource_label_events_for_update
            WHERE resource_label_events.id = resource_label_events_for_update.id
          SQL

          break if result.cmd_tuples == 0
        end
      end
    end
  end
end

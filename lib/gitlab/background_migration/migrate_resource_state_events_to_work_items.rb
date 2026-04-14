# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateResourceStateEventsToWorkItems < BatchedMigrationJob
      operation_name :migrate_resource_state_events_to_work_items
      feature_category :portfolio_management
      tables_to_check_for_vacuum :resource_state_events

      RESOURCE_STATE_EVENTS_BATCH_SIZE = 100

      def perform
        each_sub_batch do |sub_batch|
          migrate_resource_state_events(sub_batch)
        end
      end

      private

      def migrate_resource_state_events(sub_batch)
        loop do
          result = connection.execute(<<~SQL)
            WITH resource_state_events_for_update AS (
              SELECT
                resource_state_events.id AS id,
                epics.issue_id AS issue_id
              FROM resource_state_events
              INNER JOIN epics ON epics.id = resource_state_events.epic_id
              WHERE resource_state_events.epic_id IN (#{sub_batch.select(:id).to_sql})
              LIMIT #{self.class::RESOURCE_STATE_EVENTS_BATCH_SIZE}
            )
            UPDATE resource_state_events
            SET issue_id = resource_state_events_for_update.issue_id, epic_id = NULL
            FROM resource_state_events_for_update
            WHERE resource_state_events.id = resource_state_events_for_update.id
          SQL
          break if result.cmd_tuples == 0
        end
      end
    end
  end
end

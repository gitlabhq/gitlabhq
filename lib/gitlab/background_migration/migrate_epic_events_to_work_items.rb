# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateEpicEventsToWorkItems < BatchedMigrationJob
      operation_name :migrate_epic_events_to_work_items
      feature_category :portfolio_management
      tables_to_check_for_vacuum :events

      EVENTS_BATCH_SIZE = 50

      def perform
        each_sub_batch do |sub_batch|
          migrate_epic_events(sub_batch)
        end
      end

      private

      # Migrate remaining Epic events to point to the work item
      def migrate_epic_events(sub_batch)
        loop do
          result = connection.execute(<<~SQL)
            WITH events_for_update AS (
              SELECT
                events.id AS id,
                epics.issue_id AS issue_id
              FROM events
              INNER JOIN epics ON epics.id = events.target_id
              WHERE events.target_id IN (#{sub_batch.select(:id).to_sql})
                AND events.target_type = 'Epic'
              LIMIT #{EVENTS_BATCH_SIZE}
            )
            UPDATE events
            SET target_id = events_for_update.issue_id, target_type = 'WorkItem'
            FROM events_for_update
            WHERE events.id = events_for_update.id
          SQL
          break if result.cmd_tuples == 0
        end
      end
    end
  end
end

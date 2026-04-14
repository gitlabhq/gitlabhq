# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateEpicNotesToWorkItems < BatchedMigrationJob
      operation_name :migrate_epic_notes_to_work_items
      feature_category :portfolio_management
      NOTES_BATCH_SIZE = 100

      def perform
        each_sub_batch do |sub_batch|
          migrate_epic_notes(sub_batch)
        end
      end

      private

      def migrate_epic_notes(sub_batch)
        loop do
          result = connection.execute(<<~SQL)
            WITH notes_for_update AS (
              SELECT
                notes.id AS id,
                epics.issue_id AS noteable_id,
                'Issue' AS noteable_type
              FROM notes
              INNER JOIN epics ON epics.id = notes.noteable_id
              WHERE notes.noteable_id IN (#{sub_batch.select(:id).to_sql}) AND notes.noteable_type = 'Epic'
              LIMIT #{NOTES_BATCH_SIZE}
            )
            UPDATE notes
            SET noteable_id = notes_for_update.noteable_id, noteable_type = notes_for_update.noteable_type
            FROM notes_for_update
            WHERE notes.id = notes_for_update.id
          SQL
          break if result.cmd_tuples == 0
        end
      end
    end
  end
end

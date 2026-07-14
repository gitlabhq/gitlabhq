# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateEpicSentNotificationsToWorkItems < BatchedMigrationJob
      operation_name :migrate_epic_sent_notifications_to_work_items
      feature_category :portfolio_management

      SENT_NOTIFICATIONS_BATCH_SIZE = 100

      def perform
        each_sub_batch do |sub_batch|
          migrate_epic_sent_notifications(sub_batch)
        end
      end

      private

      def migrate_epic_sent_notifications(sub_batch)
        loop do
          result = connection.execute(<<~SQL)
            WITH sent_notifications_for_update AS (
              SELECT
                p_sent_notifications.id AS id,
                epics.issue_id AS noteable_id
              FROM p_sent_notifications
              INNER JOIN epics ON epics.id = p_sent_notifications.noteable_id
              WHERE p_sent_notifications.noteable_type = 'Epic'
                AND p_sent_notifications.noteable_id IN (#{sub_batch.select(:id).to_sql})
              LIMIT #{SENT_NOTIFICATIONS_BATCH_SIZE}
            )
            UPDATE p_sent_notifications
            SET noteable_id = sent_notifications_for_update.noteable_id,
                noteable_type = 'Issue'
            FROM sent_notifications_for_update
            WHERE p_sent_notifications.id = sent_notifications_for_update.id
          SQL

          break if result.cmd_tuples == 0
        end
      end
    end
  end
end

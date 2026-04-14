# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateEpicAwardEmojiToWorkItems < BatchedMigrationJob
      operation_name :migrate_epic_award_emoji_to_work_items
      feature_category :portfolio_management

      def perform
        each_sub_batch do |sub_batch|
          delete_duplicate_epic_award_emoji(sub_batch)
          migrate_epic_award_emoji(sub_batch)
        end
      end

      private

      def delete_duplicate_epic_award_emoji(sub_batch)
        connection.execute(<<~SQL)
          DELETE FROM award_emoji
          USING epics
          WHERE award_emoji.awardable_id = epics.id
            AND award_emoji.awardable_id IN (#{sub_batch.select(:id).to_sql})
            AND award_emoji.awardable_type = 'Epic'
            AND EXISTS (
              SELECT 1 FROM award_emoji AS existing
              WHERE existing.awardable_id = epics.issue_id
                AND existing.awardable_type = 'Issue'
                AND existing.user_id = award_emoji.user_id
                AND existing.name = award_emoji.name
                AND existing.namespace_id = award_emoji.namespace_id
            )
        SQL
      end

      def migrate_epic_award_emoji(sub_batch)
        connection.execute(<<~SQL)
          UPDATE award_emoji
          SET awardable_id = epics.issue_id,
              awardable_type = 'Issue'
          FROM epics
          WHERE award_emoji.awardable_id = epics.id
            AND award_emoji.awardable_id IN (#{sub_batch.select(:id).to_sql})
            AND award_emoji.awardable_type = 'Epic'
        SQL
      end
    end
  end
end

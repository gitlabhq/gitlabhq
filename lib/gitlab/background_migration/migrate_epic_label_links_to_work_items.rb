# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateEpicLabelLinksToWorkItems < BatchedMigrationJob
      operation_name :migrate_epic_label_links_to_work_items
      feature_category :portfolio_management

      def perform
        each_sub_batch do |sub_batch|
          delete_duplicate_epic_label_links(sub_batch)
          migrate_epic_label_links(sub_batch)
        end
      end

      private

      def delete_duplicate_epic_label_links(sub_batch)
        connection.execute(<<~SQL)
          DELETE FROM label_links
          USING epics
          WHERE label_links.target_id = epics.id
            AND label_links.target_id IN (#{sub_batch.select(:id).to_sql})
            AND label_links.target_type = 'Epic'
            AND EXISTS (
              SELECT 1 FROM label_links AS existing
              WHERE existing.target_id = epics.issue_id
                AND existing.target_type = 'Issue'
                AND existing.label_id = label_links.label_id
            )
        SQL
      end

      def migrate_epic_label_links(sub_batch)
        connection.execute(<<~SQL)
          UPDATE label_links
          SET target_id = epics.issue_id,
              target_type = 'Issue'
          FROM epics
          WHERE label_links.target_id = epics.id
            AND label_links.target_id IN (#{sub_batch.select(:id).to_sql})
            AND label_links.target_type = 'Epic'
        SQL
      end
    end
  end
end

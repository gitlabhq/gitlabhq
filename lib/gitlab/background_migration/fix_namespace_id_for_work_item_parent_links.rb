# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class FixNamespaceIdForWorkItemParentLinks < BatchedMigrationJob
      operation_name :fix_work_item_parent_links_namespace_id
      feature_category :team_planning

      def perform
        each_sub_batch do |sub_batch|
          sub_batch = sub_batch
            .joins("JOIN issues ON (work_item_parent_links.work_item_id = issues.id)")
            .where('work_item_parent_links.namespace_id != issues.namespace_id')

          query = <<~SQL
            UPDATE work_item_parent_links
            SET namespace_id = issues.namespace_id
            FROM issues
            WHERE issues.id = work_item_parent_links.work_item_id
            AND work_item_parent_links.id IN (#{sub_batch.select(:id).to_sql})
          SQL

          sub_batch.connection.execute(query)
        end
      end
    end
  end
end

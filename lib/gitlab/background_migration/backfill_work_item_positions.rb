# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillWorkItemPositions < BatchedMigrationJob
      operation_name :backfill_work_item_positions
      feature_category :team_planning

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(
            <<~SQL
              INSERT INTO work_item_positions (work_item_id, namespace_id, relative_position, created_at, updated_at)
              SELECT id, namespace_id, relative_position, NOW(), NOW()
              FROM (#{sub_batch.select(:id, :namespace_id, :relative_position).to_sql}) AS sub_batch
              ON CONFLICT (work_item_id) DO NOTHING
            SQL
          )
        end
      end
    end
  end
end

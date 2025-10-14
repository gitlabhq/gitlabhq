# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillTodosWithMultipleColumnShardingKey < BatchedMigrationJob
      operation_name :backfill_todos_with_multiple_column_sharding_key
      feature_category :notifications

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where.not(group_id: nil)
            .where.not(project_id: nil)
            .update_all(group_id: nil)

          connection.exec_update(update_sql(sub_batch))
        end
      end

      private

      def update_sql(sub_batch)
        <<~SQL
          UPDATE todos SET organization_id = users.organization_id
          FROM users
          WHERE todos.user_id = users.id
          AND todos.group_id IS NULL
          AND todos.project_id IS NULL
          AND todos.id IN (#{sub_batch.select(:id).to_sql})
        SQL
      end
    end
  end
end

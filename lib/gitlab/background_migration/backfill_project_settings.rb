# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Back-fill project settings for projects that do not yet have one.
    class BackfillProjectSettings
      include Gitlab::Database::DynamicModelHelpers

      def perform(start_id, end_id, batch_table, batch_column, sub_batch_size, pause_ms)
        batch_relation = relation_scoped_to_range(batch_table, batch_column, start_id, end_id)

        batch_relation.each_batch(column: batch_column, of: sub_batch_size) do |sub_batch|
          insert_sql = <<~SQL
            INSERT INTO project_settings (project_id, created_at, updated_at)
            #{sub_batch.where(project_settings: { project_id: nil })
                       .select('projects.id, NOW(), NOW()')
                       .to_sql}
            ON CONFLICT (project_id) DO NOTHING
          SQL

          connection.execute(insert_sql)

          pause_ms = 0 if pause_ms < 0
          sleep(pause_ms * 0.001)
        end
      end

      private

      def connection
        ApplicationRecord.connection
      end

      def relation_scoped_to_range(source_table, source_key_column, start_id, stop_id)
        define_batchable_model(:projects, connection: connection)
          .where(source_key_column => start_id..stop_id)
          .joins("LEFT OUTER JOIN project_settings ON project_settings.project_id = projects.id")
      end
    end
  end
end

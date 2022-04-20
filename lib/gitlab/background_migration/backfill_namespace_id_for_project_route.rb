# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfills the `routes.namespace_id` column, by setting it to project.project_namespace_id
    class BackfillNamespaceIdForProjectRoute
      include Gitlab::Database::DynamicModelHelpers

      def perform(start_id, end_id, batch_table, batch_column, sub_batch_size, pause_ms)
        parent_batch_relation = relation_scoped_to_range(batch_table, batch_column, start_id, end_id)

        parent_batch_relation.each_batch(column: batch_column, of: sub_batch_size) do |sub_batch|
          cleanup_gin_index('routes')

          batch_metrics.time_operation(:update_all) do
            ActiveRecord::Base.connection.execute <<~SQL
              WITH route_and_ns(route_id, project_namespace_id) AS #{::Gitlab::Database::AsWithMaterialized.materialized_if_supported} (
                #{sub_batch.to_sql}
              )
              UPDATE routes
              SET namespace_id = route_and_ns.project_namespace_id
              FROM route_and_ns
              WHERE id = route_and_ns.route_id
            SQL
          end

          pause_ms = [0, pause_ms].max
          sleep(pause_ms * 0.001)
        end
      end

      def batch_metrics
        @batch_metrics ||= Gitlab::Database::BackgroundMigration::BatchMetrics.new
      end

      private

      def cleanup_gin_index(table_name)
        sql = "select indexname::text from pg_indexes where tablename = '#{table_name}' and indexdef ilike '%gin%'"
        index_names = ActiveRecord::Base.connection.select_values(sql)

        index_names.each do |index_name|
          ActiveRecord::Base.connection.execute("select gin_clean_pending_list('#{index_name}')")
        end
      end

      def relation_scoped_to_range(source_table, source_key_column, start_id, stop_id)
        define_batchable_model(source_table, connection: ActiveRecord::Base.connection)
          .joins('INNER JOIN projects ON routes.source_id = projects.id')
          .where(source_key_column => start_id..stop_id)
          .where(namespace_id: nil)
          .where(source_type: 'Project')
          .where.not(projects: { project_namespace_id: nil })
          .select("routes.id, projects.project_namespace_id")
      end
    end
  end
end

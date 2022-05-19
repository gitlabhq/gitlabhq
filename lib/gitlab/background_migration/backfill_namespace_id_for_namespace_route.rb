# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfills the `routes.namespace_id` column, by copying source_id value
    # (for groups and user namespaces source_id == namespace_id)
    class BackfillNamespaceIdForNamespaceRoute
      include Gitlab::Database::DynamicModelHelpers

      def perform(start_id, end_id, batch_table, batch_column, sub_batch_size, pause_ms)
        parent_batch_relation = relation_scoped_to_range(batch_table, batch_column, start_id, end_id)

        parent_batch_relation.each_batch(column: batch_column, of: sub_batch_size) do |sub_batch|
          batch_metrics.time_operation(:update_all) do
            sub_batch.update_all('namespace_id=source_id')
          end

          pause_ms = [0, pause_ms].max
          sleep(pause_ms * 0.001)
        end
      end

      def batch_metrics
        @batch_metrics ||= Gitlab::Database::BackgroundMigration::BatchMetrics.new
      end

      private

      def relation_scoped_to_range(source_table, source_key_column, start_id, stop_id)
        define_batchable_model(source_table, connection: ApplicationRecord.connection)
          .joins('inner join namespaces on routes.source_id = namespaces.id')
          .where(source_key_column => start_id..stop_id)
          .where(namespace_id: nil)
          .where(source_type: 'Namespace')
      end
    end
  end
end

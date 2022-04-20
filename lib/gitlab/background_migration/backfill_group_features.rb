# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfill group_features for an array of groups
    class BackfillGroupFeatures < ::Gitlab::BackgroundMigration::BaseJob
      include Gitlab::Database::DynamicModelHelpers

      def perform(start_id, end_id, batch_table, batch_column, sub_batch_size, pause_ms, batch_size)
        pause_ms = 0 if pause_ms < 0

        parent_batch_relation = relation_scoped_to_range(batch_table, batch_column, start_id, end_id)
        parent_batch_relation.each_batch(column: batch_column, of: sub_batch_size, order_hint: :type) do |sub_batch|
          batch_metrics.time_operation(:upsert_group_features) do
            upsert_group_features(sub_batch, batch_size)
          end

          sleep(pause_ms * 0.001)
        end
      end

      def batch_metrics
        @batch_metrics ||= Gitlab::Database::BackgroundMigration::BatchMetrics.new
      end

      private

      def relation_scoped_to_range(source_table, source_key_column, start_id, stop_id)
        define_batchable_model(source_table, connection: connection)
          .where(source_key_column => start_id..stop_id)
          .where(type: 'Group')
      end

      def upsert_group_features(relation, batch_size)
        connection.execute(
          <<~SQL
          INSERT INTO group_features (group_id, created_at, updated_at)
          SELECT namespaces.id as group_id, now(), now()
          FROM namespaces
          WHERE namespaces.type = 'Group' AND namespaces.id IN(#{relation.select(:id).limit(batch_size).to_sql})
          ON CONFLICT (group_id) DO NOTHING;
          SQL
        )
      end
    end
  end
end

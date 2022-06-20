# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # A job to nullify orphan runner_id on ci_builds table
    class NullifyOrphanRunnerIdOnCiBuilds
      include Gitlab::Database::DynamicModelHelpers

      def perform(start_id, end_id, batch_table, batch_column, sub_batch_size, pause_ms)
        pause_ms = 0 if pause_ms < 0

        batch_relation = relation_scoped_to_range(batch_table, batch_column, start_id, end_id)
        batch_relation.each_batch(column: batch_column, of: sub_batch_size) do |sub_batch|
          batch_metrics.time_operation(:update_all) do
            filtered_sub_batch(sub_batch).update_all(runner_id: nil)
          end

          sleep(pause_ms * 0.001)
        end
      end

      def batch_metrics
        @batch_metrics ||= Gitlab::Database::BackgroundMigration::BatchMetrics.new
      end

      private

      def connection
        ::Ci::ApplicationRecord.connection
      end

      def relation_scoped_to_range(source_table, source_key_column, start_id, stop_id)
        define_batchable_model(source_table, connection: connection)
          .where(source_key_column => start_id..stop_id)
      end

      def filtered_sub_batch(sub_batch)
        sub_batch
          .joins('LEFT OUTER JOIN ci_runners ON ci_runners.id = ci_builds.runner_id')
          .where('ci_builds.runner_id IS NOT NULL AND ci_runners.id IS NULL')
      end
    end
  end
end

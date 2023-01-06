# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfills the `members.member_namespace_id` column for `type=ProjectMember`
    class BackfillProjectMemberNamespaceId < Gitlab::BackgroundMigration::BatchedMigrationJob
      feature_category :database

      def perform
        parent_batch_relation = relation_scoped_to_range(batch_table, batch_column, start_id, end_id)

        parent_batch_relation.each_batch(column: batch_column, of: sub_batch_size, order_hint: :type) do |sub_batch|
          batch_metrics.time_operation(:update_all) do
            # rubocop:disable Layout/LineLength
            sub_batch.update_all('member_namespace_id = (SELECT projects.project_namespace_id FROM projects WHERE projects.id = source_id)')
            # rubocop:enable Layout/LineLength
          end

          pause_ms_value = [0, pause_ms].max
          sleep(pause_ms_value * 0.001)
        end
      end

      def batch_metrics
        @batch_metrics ||= Gitlab::Database::BackgroundMigration::BatchMetrics.new
      end

      private

      def relation_scoped_to_range(source_table, source_key_column, start_id, stop_id)
        define_batchable_model(source_table, connection: ApplicationRecord.connection)
          .where(source_key_column => start_id..stop_id)
          .joins('INNER JOIN projects ON members.source_id = projects.id')
          .where(type: 'ProjectMember', source_type: 'Project')
          .where(member_namespace_id: nil)
      end
    end
  end
end

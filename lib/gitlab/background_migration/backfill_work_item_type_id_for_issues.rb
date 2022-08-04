# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfills the `issues.work_item_type_id` column, replacing any
    # instances of `NULL` with the appropriate `work_item_types.id` based on `issues.issue_type`
    class BackfillWorkItemTypeIdForIssues
      # Basic AR model for issues table
      class MigrationIssue < ApplicationRecord
        include ::EachBatch

        self.table_name = 'issues'

        scope :base_query, ->(base_type) { where(work_item_type_id: nil, issue_type: base_type) }
      end

      MAX_UPDATE_RETRIES = 3

      def perform(start_id, end_id, batch_table, batch_column, sub_batch_size, pause_ms, base_type, base_type_id)
        parent_batch_relation = relation_scoped_to_range(batch_table, batch_column, start_id, end_id, base_type)

        parent_batch_relation.each_batch(column: batch_column, of: sub_batch_size) do |sub_batch|
          first, last = sub_batch.pick(Arel.sql('min(id), max(id)'))

          # The query need to be reconstructed because .each_batch modifies the default scope
          # See: https://gitlab.com/gitlab-org/gitlab/-/issues/330510
          reconstructed_sub_batch = MigrationIssue.unscoped.base_query(base_type).where(id: first..last)

          batch_metrics.time_operation(:update_all) do
            update_with_retry(reconstructed_sub_batch, base_type_id)
          end

          pause_ms = 0 if pause_ms < 0
          sleep(pause_ms * 0.001)
        end
      end

      def batch_metrics
        @batch_metrics ||= Gitlab::Database::BackgroundMigration::BatchMetrics.new
      end

      private

      # Retry mechanism required as update statements on the issues table will randomly take longer than
      # expected due to gin indexes https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71869#note_775796352
      def update_with_retry(sub_batch, base_type_id)
        update_attempt = 1

        begin
          update_batch(sub_batch, base_type_id)
        rescue ActiveRecord::StatementTimeout, ActiveRecord::QueryCanceled => e
          update_attempt += 1

          if update_attempt <= MAX_UPDATE_RETRIES
            # sleeping 30 seconds as it might take a long time to clean the gin index pending list
            sleep(30)
            retry
          end

          raise e
        end
      end

      def update_batch(sub_batch, base_type_id)
        sub_batch.update_all(work_item_type_id: base_type_id)
      end

      def relation_scoped_to_range(source_table, source_key_column, start_id, end_id, base_type)
        MigrationIssue.where(source_key_column => start_id..end_id).base_query(base_type)
      end
    end
  end
end

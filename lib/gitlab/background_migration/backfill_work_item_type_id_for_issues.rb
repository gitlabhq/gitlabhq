# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfills the `issues.work_item_type_id` column, replacing any
    # instances of `NULL` with the appropriate `work_item_types.id` based on `issues.issue_type`
    class BackfillWorkItemTypeIdForIssues < BatchedMigrationJob
      feature_category :database

      # Basic AR model for issues table
      class MigrationIssue < ApplicationRecord
        self.table_name = 'issues'

        scope :base_query, ->(base_type) { where(issue_type: base_type) }
      end

      MAX_UPDATE_RETRIES = 3

      scope_to ->(relation) {
        relation.where(issue_type: base_type)
      }

      job_arguments :base_type, :base_type_id
      operation_name :update_all

      def perform
        each_sub_batch do |sub_batch|
          first, last = sub_batch.pick(Arel.sql('min(id), max(id)'))

          # The query need to be reconstructed because .each_batch modifies the default scope
          # See: https://gitlab.com/gitlab-org/gitlab/-/issues/330510
          reconstructed_sub_batch = MigrationIssue.unscoped.base_query(base_type).where(id: first..last)

          update_with_retry(reconstructed_sub_batch, base_type_id)
        end
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
    end
  end
end

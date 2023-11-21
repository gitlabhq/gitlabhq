# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This migration populates the new `merge_request_diffs.project_id` column from joining with `merge_requests` table
    class BackfillMergeRequestDiffsProjectId < BatchedMigrationJob
      operation_name :update_all
      scope_to ->(relation) { relation.where(project_id: nil) }

      feature_category :code_review_workflow

      def perform
        each_sub_batch do |sub_batch|
          ApplicationRecord.connection.execute <<-SQL
            UPDATE merge_request_diffs
            SET project_id = merge_requests.target_project_id
            FROM merge_requests
            WHERE merge_requests.id = merge_request_diffs.merge_request_id
            AND merge_request_diffs.id IN (#{sub_batch.select(:id).to_sql})
          SQL
        end
      end
    end
  end
end

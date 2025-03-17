# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMergeRequestContextCommitDiffFilesProjectId < BatchedMigrationJob
      operation_name :backfill_merge_request_context_commit_diff_files_project_id
      feature_category :code_review_workflow
      cursor :merge_request_context_commit_id, :relative_order

      def perform
        each_sub_batch do |relation|
          connection.execute(<<~SQL)
            WITH batched_relation AS (
              #{relation.where(project_id: nil).select(:merge_request_context_commit_id, :relative_order).to_sql}
            )
            UPDATE merge_request_context_commit_diff_files
            SET project_id = merge_request_context_commits.project_id
            FROM batched_relation
            INNER JOIN merge_request_context_commits ON batched_relation.merge_request_context_commit_id = merge_request_context_commits.id
            WHERE merge_request_context_commit_diff_files.merge_request_context_commit_id = batched_relation.merge_request_context_commit_id
              AND merge_request_context_commit_diff_files.relative_order = batched_relation.relative_order;
          SQL
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMergeRequestsMergeDataFromMergeRequests < BatchedMigrationJob
      operation_name :backfill_merge_requests_merge_data_from_merge_requests
      feature_category :code_review_workflow

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(<<~SQL)
            INSERT INTO merge_requests_merge_data (
              merge_request_id,
              project_id,
              merge_user_id,
              merge_params,
              merge_error,
              merge_jid,
              merge_commit_sha,
              merged_commit_sha,
              merge_ref_sha,
              squash_commit_sha,
              in_progress_merge_commit_sha,
              merge_status,
              auto_merge_enabled,
              squash
            )
            #{select_clause(sub_batch)}
            ON CONFLICT DO NOTHING
          SQL
        end
      end

      private

      def select_clause(sub_batch)
        <<~SQL
          SELECT
            mr.id AS merge_request_id,
            mr.target_project_id AS project_id,
            mr.merge_user_id,
            mr.merge_params,
            mr.merge_error,
            mr.merge_jid,
            CASE
              WHEN mr.merge_commit_sha IS NOT NULL AND mr.merge_commit_sha != 'f'
              THEN decode(mr.merge_commit_sha, 'hex')
            END AS merge_commit_sha,
            CASE
              WHEN mr.merged_commit_sha IS NOT NULL
              THEN decode(encode(mr.merged_commit_sha, 'escape'), 'hex')
            END AS merged_commit_sha,
            mr.merge_ref_sha,
            mr.squash_commit_sha,
            CASE
              WHEN mr.in_progress_merge_commit_sha IS NOT NULL
              THEN decode(mr.in_progress_merge_commit_sha, 'hex')
            END AS in_progress_merge_commit_sha,
            CASE mr.merge_status
              WHEN 'unchecked' THEN 0
              WHEN 'preparing' THEN 1
              WHEN 'checking' THEN 2
              WHEN 'can_be_merged' THEN 3
              WHEN 'cannot_be_merged' THEN 4
              WHEN 'cannot_be_merged_recheck' THEN 5
              WHEN 'cannot_be_merged_rechecking' THEN 6
              ELSE 0
            END AS merge_status,
            mr.merge_when_pipeline_succeeds AS auto_merge_enabled,
            mr.squash
          FROM merge_requests AS mr
          LEFT JOIN merge_requests_merge_data mmd
            ON mmd.merge_request_id = mr.id
          WHERE mr.id BETWEEN #{sub_batch.first.id} AND #{sub_batch.last.id}
            AND mmd.merge_request_id IS NULL
        SQL
      end
    end
  end
end

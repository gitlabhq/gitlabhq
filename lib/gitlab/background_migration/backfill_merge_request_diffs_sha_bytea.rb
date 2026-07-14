# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMergeRequestDiffsShaBytea < BatchedMigrationJob
      operation_name :backfill_merge_request_diffs_sha_bytea
      feature_category :code_review_workflow

      def perform
        each_sub_batch do |sub_batch|
          # Stacked MATERIALIZED CTEs with explicit LIMITs keep the access path
          # PK-bounded and stable, avoiding plan flips as the backfill changes
          # the selectivity of the *_bytea IS NULL predicate over time.
          connection.execute(<<~SQL)
            WITH relation AS MATERIALIZED (
              #{sub_batch.limit(sub_batch_size).to_sql}
            ), filtered_relation AS MATERIALIZED (
              SELECT id
              FROM relation
              WHERE base_commit_sha_bytea IS NULL
                AND start_commit_sha_bytea IS NULL
                AND head_commit_sha_bytea IS NULL
                AND (base_commit_sha IS NOT NULL
                  OR start_commit_sha IS NOT NULL
                  OR head_commit_sha IS NOT NULL)
              LIMIT #{sub_batch_size}
            )
            UPDATE merge_request_diffs
            SET base_commit_sha_bytea  = decode(base_commit_sha,  'hex'),
                start_commit_sha_bytea = decode(start_commit_sha, 'hex'),
                head_commit_sha_bytea  = decode(head_commit_sha,  'hex')
            FROM filtered_relation
            WHERE merge_request_diffs.id = filtered_relation.id
          SQL
        end
      end
    end
  end
end

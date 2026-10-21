# frozen_string_literal: true

class CopyAiSuggestedReviewersToPartitionedTable < Gitlab::Database::Migration[2.4]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  milestone '19.6'

  SOURCE_TABLE = :ai_suggested_reviewers
  TARGET_TABLE = :p_ai_suggested_reviewers
  RETENTION_PERIOD = 30.days
  BATCH_SIZE = 500

  def up
    oldest_date = (Time.now.utc - RETENTION_PERIOD).to_date

    define_batchable_model(SOURCE_TABLE).distinct_each_batch(column: :merge_request_id, of: BATCH_SIZE) do |batch|
      merge_request_ids = batch.pluck(:merge_request_id)

      execute(<<~SQL)
        INSERT INTO #{TARGET_TABLE}
          (project_id, merge_request_id, user_id, approval_merge_request_rule_id,
           approval_project_rule_id, created_at, updated_at, reason)
        SELECT source.project_id, source.merge_request_id, source.user_id, source.approval_merge_request_rule_id,
          source.approval_project_rule_id, source.created_at, source.updated_at, source.reason
        FROM #{SOURCE_TABLE} source
        WHERE source.merge_request_id IN (#{merge_request_ids.join(', ')})
          AND source.created_at >= #{connection.quote(oldest_date.iso8601)}
          AND NOT EXISTS (
            SELECT 1 FROM #{TARGET_TABLE} target
            WHERE target.merge_request_id = source.merge_request_id
          )
        ORDER BY source.id
      SQL
    end
  end

  def down
    # no-op
  end
end

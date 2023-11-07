# frozen_string_literal: true

class BackfillPCiBuildsPipelineId < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  milestone '16.6'

  TABLE_NAME = :ci_builds
  COLUMN_NAMES = %i[
    auto_canceled_by_id
    commit_id
    erased_by_id
    project_id
    runner_id
    trigger_request_id
    upstream_pipeline_id
    user_id
  ]
  SUB_BATCH_SIZE = 750
  BATCH_SIZE = 75_000
  PAUSE_MS = 0

  def up
    backfill_conversion_of_integer_to_bigint(
      TABLE_NAME, COLUMN_NAMES,
      sub_batch_size: SUB_BATCH_SIZE,
      batch_size: BATCH_SIZE,
      pause_ms: PAUSE_MS
    )
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint(TABLE_NAME, COLUMN_NAMES)
  end
end

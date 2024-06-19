# frozen_string_literal: true

class CleanupBigintConversionsForPCiBuilds < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  enable_lock_retries!

  TABLE_NAME = :p_ci_builds
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

  def up
    cleanup_conversion_of_integer_to_bigint(TABLE_NAME, COLUMN_NAMES)
  end

  def down
    restore_conversion_of_integer_to_bigint(TABLE_NAME, COLUMN_NAMES)
  end
end

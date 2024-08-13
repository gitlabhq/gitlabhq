# frozen_string_literal: true

class CleanupBigintConversionForMergeRequestsHeadPipelineId < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  enable_lock_retries!

  TABLE = :merge_requests
  COLUMNS = [:head_pipeline_id]

  def up
    cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    restore_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end

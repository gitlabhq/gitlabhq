# frozen_string_literal: true

class CleanupBigintConversionForMergeRequestMetricsPipelineId < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  TABLE = :merge_request_metrics
  COLUMNS = [:pipeline_id]

  def up
    cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    restore_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end

# frozen_string_literal: true

class InitConversionForMergeRequestMetricsPipelineIdBigint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.11'

  TABLE = :merge_request_metrics
  COLUMN = :pipeline_id

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMN)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMN)
  end
end

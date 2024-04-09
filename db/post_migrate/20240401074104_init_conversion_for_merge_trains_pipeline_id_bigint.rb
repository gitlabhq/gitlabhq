# frozen_string_literal: true

class InitConversionForMergeTrainsPipelineIdBigint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.11'

  TABLE = :merge_trains
  COLUMN = :pipeline_id

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMN)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMN)
  end
end

# frozen_string_literal: true

class ValidateAsyncFkOnPCiStagesPartitionIdAndPipelineId < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  TABLE_NAME = :p_ci_stages
  FK_NAME = :fk_fb57e6cc56_p
  COLUMNS = [:partition_id, :pipeline_id]

  def up
    prepare_partitioned_async_foreign_key_validation(TABLE_NAME, COLUMNS, name: FK_NAME)
  end

  def down
    unprepare_partitioned_async_foreign_key_validation(TABLE_NAME, COLUMNS, name: FK_NAME)
  end
end

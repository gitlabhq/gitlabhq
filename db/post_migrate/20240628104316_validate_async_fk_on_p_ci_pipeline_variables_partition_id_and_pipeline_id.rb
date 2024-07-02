# frozen_string_literal: true

class ValidateAsyncFkOnPCiPipelineVariablesPartitionIdAndPipelineId < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  TABLE_NAME = :p_ci_pipeline_variables
  FK_NAME = :fk_f29c5f4380_p
  COLUMNS = [:partition_id, :pipeline_id]

  def up
    prepare_partitioned_async_foreign_key_validation(TABLE_NAME, COLUMNS, name: FK_NAME)
  end

  def down
    unprepare_partitioned_async_foreign_key_validation(TABLE_NAME, COLUMNS, name: FK_NAME)
  end
end

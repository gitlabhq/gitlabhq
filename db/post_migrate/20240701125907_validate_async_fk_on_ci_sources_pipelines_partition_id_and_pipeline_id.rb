# frozen_string_literal: true

class ValidateAsyncFkOnCiSourcesPipelinesPartitionIdAndPipelineId < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  TABLE_NAME = :ci_sources_pipelines
  FK_NAME = :fk_e1bad85861_p
  COLUMNS = [:partition_id, :pipeline_id]

  def up
    prepare_async_foreign_key_validation(TABLE_NAME, COLUMNS, name: FK_NAME)
  end

  def down
    unprepare_async_foreign_key_validation(TABLE_NAME, COLUMNS, name: FK_NAME)
  end
end

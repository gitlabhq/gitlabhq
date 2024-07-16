# frozen_string_literal: true

class ValidateAsyncFkOnCiPipelineArtifactsPartitionIdAndPipelineId < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  TABLE_NAME = :ci_pipeline_artifacts
  FK_NAME = :fk_rails_a9e811a466_p
  COLUMNS = [:partition_id, :pipeline_id]

  def up
    prepare_async_foreign_key_validation(TABLE_NAME, COLUMNS, name: FK_NAME)
  end

  def down
    unprepare_async_foreign_key_validation(TABLE_NAME, COLUMNS, name: FK_NAME)
  end
end

# frozen_string_literal: true

class ValidateAsyncFkOnCiPipelineMetadataPartitionIdAndPipelineId < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  TABLE_NAME = :ci_pipeline_metadata
  FK_NAME = :fk_rails_50c1e9ea10_p
  COLUMNS = [:partition_id, :pipeline_id]

  def up
    prepare_async_foreign_key_validation(TABLE_NAME, COLUMNS, name: FK_NAME)
  end

  def down
    unprepare_async_foreign_key_validation(TABLE_NAME, COLUMNS, name: FK_NAME)
  end
end

# frozen_string_literal: true

class ValidateAsyncFkOnCiPipelinesConfigPartitionIdAndPipelineId < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  TABLE_NAME = :ci_pipelines_config
  FK_NAME = :fk_rails_906c9a2533_p
  COLUMNS = [:partition_id, :pipeline_id]

  def up
    prepare_async_foreign_key_validation(TABLE_NAME, COLUMNS, name: FK_NAME)
  end

  def down
    unprepare_async_foreign_key_validation(TABLE_NAME, COLUMNS, name: FK_NAME)
  end
end

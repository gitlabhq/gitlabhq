# frozen_string_literal: true

class ValidateAsyncFkOnCiPipelineMessagesPartitionIdAndPipelineId < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  TABLE_NAME = :ci_pipeline_messages
  FK_NAME = :fk_rails_8d3b04e3e1_p
  COLUMNS = [:partition_id, :pipeline_id]

  def up
    prepare_async_foreign_key_validation(TABLE_NAME, COLUMNS, name: FK_NAME)
  end

  def down
    unprepare_async_foreign_key_validation(TABLE_NAME, COLUMNS, name: FK_NAME)
  end
end

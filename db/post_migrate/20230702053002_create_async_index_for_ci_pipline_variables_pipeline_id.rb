# frozen_string_literal: true

class CreateAsyncIndexForCiPiplineVariablesPipelineId < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_pipeline_variables
  INDEX_NAME = "index_ci_pipeline_variables_on_pipeline_id_bigint_and_key"

  def up
    prepare_async_index TABLE_NAME, [:pipeline_id_convert_to_bigint, :key], unique: true, name: INDEX_NAME
  end

  def down
    unprepare_async_index TABLE_NAME, [:pipeline_id_convert_to_bigint, :key], unique: true, name: INDEX_NAME
  end
end

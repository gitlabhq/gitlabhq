# frozen_string_literal: true

class CreateSyncIndexForCiPiplineVariablesPipelineId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :ci_pipeline_variables
  INDEX_NAME = 'index_ci_pipeline_variables_on_pipeline_id_bigint_and_key'
  COLUMNS = [:pipeline_id_convert_to_bigint, :key]

  def up
    add_concurrent_index TABLE_NAME, COLUMNS, unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end

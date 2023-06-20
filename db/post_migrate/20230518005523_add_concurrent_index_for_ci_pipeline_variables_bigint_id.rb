# frozen_string_literal: true

class AddConcurrentIndexForCiPipelineVariablesBigintId < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  TABLE_NAME = :ci_pipeline_variables
  INDEX_NAME = "index_#{TABLE_NAME}_on_id_convert_to_bigint"

  def up
    add_concurrent_index TABLE_NAME, :id_convert_to_bigint, unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end

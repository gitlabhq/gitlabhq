# frozen_string_literal: true

class PrepareAsyncIndexForCiPipelineVariablesBigintId < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_pipeline_variables
  INDEX_NAME = "index_#{TABLE_NAME}_on_id_convert_to_bigint"

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/408936
  def up
    prepare_async_index TABLE_NAME, :id_convert_to_bigint, unique: true, name: INDEX_NAME
  end

  def down
    unprepare_async_index TABLE_NAME, :id_convert_to_bigint, unique: true, name: INDEX_NAME
  end
end

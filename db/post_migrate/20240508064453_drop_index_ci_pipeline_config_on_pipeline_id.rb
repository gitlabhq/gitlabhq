# frozen_string_literal: true

class DropIndexCiPipelineConfigOnPipelineId < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  disable_ddl_transaction!

  TABLE_NAME = :ci_pipelines_config
  INDEX_NAME = :index_ci_pipelines_config_on_pipeline_id

  def up
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, :pipeline_id, name: INDEX_NAME)
  end
end

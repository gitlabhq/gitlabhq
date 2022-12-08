# frozen_string_literal: true

class RemovePipelineMetadataPipelineIdIndex < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_pipeline_metadata_on_pipeline_id_name'

  def up
    remove_concurrent_index_by_name :ci_pipeline_metadata, INDEX_NAME
  end

  def down
    add_concurrent_index :ci_pipeline_metadata, [:pipeline_id, :name], name: INDEX_NAME
  end
end

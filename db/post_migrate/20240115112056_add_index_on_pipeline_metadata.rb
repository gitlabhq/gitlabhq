# frozen_string_literal: true

class AddIndexOnPipelineMetadata < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.8'

  INDEX_NAME = 'index_pipeline_metadata_on_name_text_pattern_pipeline_id'

  def up
    add_concurrent_index :ci_pipeline_metadata, 'name text_pattern_ops, pipeline_id', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_pipeline_metadata, INDEX_NAME
  end
end

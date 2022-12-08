# frozen_string_literal: true

class AddPipelineMetadataNameIndex < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_pipeline_metadata_on_pipeline_id_name_lower_text_pattern'

  def up
    add_concurrent_index :ci_pipeline_metadata, 'pipeline_id, lower(name) text_pattern_ops', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_pipeline_metadata, INDEX_NAME
  end
end

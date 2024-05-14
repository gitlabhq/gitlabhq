# frozen_string_literal: true

class RemoveIndexOnPipelineMetadata < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.10'

  INDEX_NAME = 'index_pipeline_metadata_on_pipeline_id_name_text_pattern'

  def up
    remove_concurrent_index_by_name :ci_pipeline_metadata, INDEX_NAME
  end

  def down
    add_concurrent_index :ci_pipeline_metadata, 'pipeline_id, name text_pattern_ops', name: INDEX_NAME
  end
end

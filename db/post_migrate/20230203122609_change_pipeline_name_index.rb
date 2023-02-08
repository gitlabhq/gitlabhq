# frozen_string_literal: true

class ChangePipelineNameIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_pipeline_metadata_on_pipeline_id_name_lower_text_pattern'
  NEW_INDEX_NAME = 'index_pipeline_metadata_on_pipeline_id_name_text_pattern'

  def up
    add_concurrent_index :ci_pipeline_metadata, 'pipeline_id, name text_pattern_ops', name: NEW_INDEX_NAME

    remove_concurrent_index_by_name :ci_pipeline_metadata, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :ci_pipeline_metadata, 'pipeline_id, lower(name) text_pattern_ops', name: OLD_INDEX_NAME

    remove_concurrent_index_by_name :ci_pipeline_metadata, NEW_INDEX_NAME
  end
end

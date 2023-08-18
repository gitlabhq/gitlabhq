# frozen_string_literal: true

class AddIndexPipelineIdToDependencyListExports < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_dependency_list_exports_on_pipeline_id'

  def up
    add_concurrent_index :dependency_list_exports, :pipeline_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :dependency_list_exports, INDEX_NAME
  end
end

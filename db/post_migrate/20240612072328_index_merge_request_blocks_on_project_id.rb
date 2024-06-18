# frozen_string_literal: true

class IndexMergeRequestBlocksOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_merge_request_blocks_on_project_id'

  def up
    add_concurrent_index :merge_request_blocks, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_request_blocks, INDEX_NAME
  end
end

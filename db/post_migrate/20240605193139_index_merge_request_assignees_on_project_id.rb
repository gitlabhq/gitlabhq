# frozen_string_literal: true

class IndexMergeRequestAssigneesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_merge_request_assignees_on_project_id'

  def up
    add_concurrent_index :merge_request_assignees, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_request_assignees, INDEX_NAME
  end
end

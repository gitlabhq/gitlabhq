# frozen_string_literal: true

class AddIndexMergeRequestDiffCommitsProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  disable_ddl_transaction!

  INDEX_NAME = 'index_merge_request_diff_commits_on_project_id'

  def up
    add_concurrent_index :merge_request_diff_commits, :project_id, name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- Need while reading from the old table before the new one is swapped
  end

  def down
    remove_concurrent_index_by_name :merge_request_diff_commits, INDEX_NAME
  end
end

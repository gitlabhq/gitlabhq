# frozen_string_literal: true

class PrepareIndexMergeRequestDiffCommitsB5377a7a34OnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  INDEX_NAME = 'index_merge_request_diff_commits_b5377a7a34_on_project_id'

  def up
    prepare_async_index :merge_request_diff_commits_b5377a7a34, :project_id, name: INDEX_NAME
  end

  def down
    unprepare_async_index :merge_request_diff_commits_b5377a7a34, INDEX_NAME
  end
end

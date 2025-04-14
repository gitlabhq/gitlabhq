# frozen_string_literal: true

class CreateAsyncIndexOnMergeRequestDiffFilesProjectId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.11'

  INDEX_NAME = 'index_merge_request_diff_files_on_project_id'

  # rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/gitlab/-/issues/512949
  def up
    add_concurrent_index :merge_request_diff_files, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_request_diff_files, INDEX_NAME
  end
end
# rubocop:enable Migration/PreventIndexCreation

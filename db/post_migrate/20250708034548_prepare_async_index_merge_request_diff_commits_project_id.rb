# frozen_string_literal: true

class PrepareAsyncIndexMergeRequestDiffCommitsProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  INDEX_NAME = 'index_merge_request_diff_commits_on_project_id'

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/554107
  def up
    prepare_async_index :merge_request_diff_commits, :project_id, name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- Need while reading from the old table before the new one is swapped
  end

  def down
    unprepare_async_index :merge_request_diff_commits, :project_id, name: INDEX_NAME
  end
end

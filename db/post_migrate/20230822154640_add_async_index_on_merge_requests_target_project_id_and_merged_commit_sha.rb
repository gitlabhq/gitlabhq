# frozen_string_literal: true

class AddAsyncIndexOnMergeRequestsTargetProjectIdAndMergedCommitSha < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_merge_requests_on_target_project_id_and_merged_commit_sha'
  INDEX_COLUMNS = %i[target_project_id merged_commit_sha]

  disable_ddl_transaction!

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/418822
  def up
    prepare_async_index :merge_requests, INDEX_COLUMNS, name: INDEX_NAME
  end

  def down
    unprepare_async_index :merge_requests, INDEX_COLUMNS, name: INDEX_NAME
  end
end

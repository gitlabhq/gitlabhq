# frozen_string_literal: true

class AddIndexToMergeRequestDiffsOnHeadCommitShaBytea < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  TABLE_NAME = :merge_request_diffs
  INDEX_NAME = :index_merge_request_diffs_on_head_commit_sha_bytea
  COLUMN     = :head_commit_sha_bytea

  def up
    # rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/635
    add_concurrent_index TABLE_NAME, COLUMN, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end

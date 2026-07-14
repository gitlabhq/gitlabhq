# frozen_string_literal: true

class PrepareAsyncIndexOnMergeRequestDiffsHeadCommitShaBytea < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  TABLE_NAME = :merge_request_diffs
  INDEX_NAME = :index_merge_request_diffs_on_head_commit_sha_bytea
  COLUMN     = :head_commit_sha_bytea

  def up
    # rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/635
    # head_commit_sha is being converted from varchar (hex)
    # to bytea (binary) storage to shrink heap and
    # index footprint. The existing varchar index will be dropped
    # together with the head_commit_sha varchar column in a later milestone,
    # leaving this index as the sole head_commit_sha index.
    prepare_async_index TABLE_NAME, COLUMN, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    unprepare_async_index TABLE_NAME, COLUMN, name: INDEX_NAME
  end
end

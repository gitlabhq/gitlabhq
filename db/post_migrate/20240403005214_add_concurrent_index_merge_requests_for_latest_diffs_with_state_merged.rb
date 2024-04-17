# frozen_string_literal: true

class AddConcurrentIndexMergeRequestsForLatestDiffsWithStateMerged < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  disable_ddl_transaction!

  TABLE_NAME = :merge_requests
  INDEX_NAME = 'index_merge_requests_for_latest_diffs_with_state_merged'

  def up
    add_concurrent_index(
      TABLE_NAME,
      [:latest_merge_request_diff_id, :target_project_id],
      where: 'state_id = 3',
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end

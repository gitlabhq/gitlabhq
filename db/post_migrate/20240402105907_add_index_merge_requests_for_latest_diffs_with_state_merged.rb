# frozen_string_literal: true

class AddIndexMergeRequestsForLatestDiffsWithStateMerged < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  disable_ddl_transaction!

  TABLE_NAME = :merge_requests
  INDEX_NAME = 'index_merge_requests_for_latest_diffs_with_state_merged'

  def up
    prepare_async_index(
      TABLE_NAME,
      [:latest_merge_request_diff_id, :target_project_id],
      where: 'state_id = 3',
      name: INDEX_NAME
    )
  end

  def down
    unprepare_async_index(
      TABLE_NAME,
      [:latest_merge_request_diff_id, :target_project_id],
      name: INDEX_NAME
    )
  end
end

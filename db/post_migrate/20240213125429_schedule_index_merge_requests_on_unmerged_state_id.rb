# frozen_string_literal: true

class ScheduleIndexMergeRequestsOnUnmergedStateId < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  INDEX_NAME = :idx_merge_requests_on_unmerged_state_id
  TABLE_NAME = :merge_requests

  def up
    # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
    prepare_async_index(TABLE_NAME, :id, name: INDEX_NAME, where: "state_id <> 3")
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    unprepare_async_index(TABLE_NAME, :id, name: INDEX_NAME)
  end
end

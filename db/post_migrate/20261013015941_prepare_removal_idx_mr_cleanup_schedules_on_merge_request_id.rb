# frozen_string_literal: true

class PrepareRemovalIdxMrCleanupSchedulesOnMergeRequestId < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  INDEX_NAME = 'index_merge_request_cleanup_schedules_on_merge_request_id'

  def up
    prepare_async_index_removal :merge_request_cleanup_schedules, :merge_request_id, name: INDEX_NAME
  end

  def down
    unprepare_async_index_by_name :merge_request_cleanup_schedules, INDEX_NAME
  end
end

# frozen_string_literal: true

class ScheduleIndexOnMergeRequestDiffsIdAndProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  INDEX_NAME = 'index_merge_request_diffs_on_project_id_and_id'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- This index will replace index_merge_request_diffs_on_project_id
    prepare_async_index :merge_request_diffs, [:project_id, :id], name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    unprepare_async_index :merge_request_diffs, [:project_id, :id], name: INDEX_NAME
  end
end

# frozen_string_literal: true

class DropIdxMergeRequestsOnTargetProjectIdAndIidOpened < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  INDEX_NAME = 'idx_merge_requests_on_target_project_id_and_iid_opened'
  COLUMN_NAMES = %i[target_project_id iid]

  # TODO: Index to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/455498
  def up
    prepare_async_index_removal :merge_requests, COLUMN_NAMES, name: INDEX_NAME
  end

  def down
    unprepare_async_index :merge_requests, COLUMN_NAMES, name: INDEX_NAME
  end
end

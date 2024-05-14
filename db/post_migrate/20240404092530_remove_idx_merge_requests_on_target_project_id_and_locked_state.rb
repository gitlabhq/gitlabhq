# frozen_string_literal: true

class RemoveIdxMergeRequestsOnTargetProjectIdAndLockedState < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  INDEX_NAME = 'idx_merge_requests_on_target_project_id_and_locked_state'
  COLUMN_NAME = :target_project_id

  # TODO: Index to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/454457
  def up
    prepare_async_index_removal :merge_requests, COLUMN_NAME, name: INDEX_NAME
  end

  def down
    unprepare_async_index :merge_requests, COLUMN_NAME, name: INDEX_NAME
  end
end

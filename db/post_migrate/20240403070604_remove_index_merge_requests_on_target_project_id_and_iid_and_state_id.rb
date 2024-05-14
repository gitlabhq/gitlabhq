# frozen_string_literal: true

class RemoveIndexMergeRequestsOnTargetProjectIdAndIidAndStateId < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  INDEX_NAME = 'index_merge_requests_on_target_project_id_and_iid_and_state_id'
  COLUMN_NAMES = %i[target_project_id iid state_id]

  # TODO: Index to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/454262
  def up
    prepare_async_index_removal :merge_requests, COLUMN_NAMES, name: INDEX_NAME
  end

  def down
    unprepare_async_index :merge_requests, COLUMN_NAMES, name: INDEX_NAME
  end
end

# frozen_string_literal: true

class AddUpdatedStateByUserIdToMergeRequestAssignees < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    add_column :merge_request_assignees, :updated_state_by_user_id, :bigint
  end
end

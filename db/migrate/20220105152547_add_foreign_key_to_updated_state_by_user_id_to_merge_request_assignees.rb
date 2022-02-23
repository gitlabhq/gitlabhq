# frozen_string_literal: true

class AddForeignKeyToUpdatedStateByUserIdToMergeRequestAssignees < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :merge_request_assignees, :users, column: :updated_state_by_user_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key :merge_request_assignees, column: :updated_state_by_user_id
    end
  end
end

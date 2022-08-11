# frozen_string_literal: true

class AddUserIdFkeyForUserProjectCallout < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :user_project_callouts, :users, column: :user_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :user_project_callouts, column: :user_id
    end
  end
end

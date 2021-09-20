# frozen_string_literal: true

class AddGroupIdFkeyForUserGroupCallout < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :user_group_callouts, :namespaces, column: :group_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :user_group_callouts, column: :group_id
    end
  end
end

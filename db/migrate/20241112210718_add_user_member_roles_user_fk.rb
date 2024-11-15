# frozen_string_literal: true

class AddUserMemberRolesUserFk < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :user_member_roles, :users, column: :user_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :user_member_roles, column: :user_id
    end
  end
end

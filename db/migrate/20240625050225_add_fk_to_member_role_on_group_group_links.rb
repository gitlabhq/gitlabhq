# frozen_string_literal: true

class AddFkToMemberRoleOnGroupGroupLinks < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :group_group_links, :member_roles, column: :member_role_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key :group_group_links, column: :member_role_id
    end
  end
end

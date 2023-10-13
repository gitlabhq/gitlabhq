# frozen_string_literal: true

class AddAdminMembersToMemberRole < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    add_column :member_roles, :admin_group_member, :boolean, default: false, null: false
  end

  def down
    remove_column :member_roles, :admin_group_member
  end
end

# frozen_string_literal: true

class AddMemberRoleIdToMembers < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    add_column :members, :member_role_id, :bigint
  end

  def down
    remove_column :members, :member_role_id
  end
end

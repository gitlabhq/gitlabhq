# frozen_string_literal: true

class AddMemberRoleIdToGroupGroupLinks < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  enable_lock_retries!

  def change
    add_column :group_group_links, :member_role_id, :bigint, if_not_exists: true
  end
end

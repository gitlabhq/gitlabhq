# frozen_string_literal: true

class AddMemberRoleIdToProjectGroupLinks < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  enable_lock_retries!

  def change
    add_column :project_group_links, :member_role_id, :bigint, if_not_exists: true
  end
end

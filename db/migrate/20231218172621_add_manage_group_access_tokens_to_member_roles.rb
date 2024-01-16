# frozen_string_literal: true

class AddManageGroupAccessTokensToMemberRoles < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  enable_lock_retries!

  def change
    add_column :member_roles, :manage_group_access_tokens, :boolean, default: false, null: false
  end
end

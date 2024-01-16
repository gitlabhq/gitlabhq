# frozen_string_literal: true

class AddAdminTerraformStateToMemberRoles < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  enable_lock_retries!

  def change
    add_column :member_roles, :admin_terraform_state, :boolean, default: false, null: false
  end
end

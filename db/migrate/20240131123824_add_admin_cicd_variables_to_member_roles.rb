# frozen_string_literal: true

class AddAdminCicdVariablesToMemberRoles < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  enable_lock_retries!

  def up
    add_column :member_roles, :admin_cicd_variables, :boolean, default: false, null: false
  end

  def down
    remove_column :member_roles, :admin_cicd_variables
  end
end

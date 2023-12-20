# frozen_string_literal: true

class AddRemoveProjectToMemberRoles < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  enable_lock_retries!

  def change
    add_column :member_roles, :remove_project, :boolean, default: false, null: false
  end
end

# frozen_string_literal: true

class AddArchiveProjectToMemberRoles < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :member_roles, :archive_project, :boolean, default: false, null: false
  end
end

# frozen_string_literal: true

class RemoveMemberRoleDownloadCode < Gitlab::Database::Migration[2.1]
  def change
    remove_column :member_roles, :download_code, :boolean, default: false
  end
end

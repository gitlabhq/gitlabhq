# frozen_string_literal: true

class AddProjectsDeletedToBannedUsers < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  def change
    add_column :banned_users, :projects_deleted, :boolean, default: false, null: false
  end
end

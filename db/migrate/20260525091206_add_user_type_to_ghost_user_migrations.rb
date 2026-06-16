# frozen_string_literal: true

class AddUserTypeToGhostUserMigrations < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def change
    add_column :ghost_user_migrations, :user_type, :integer, limit: 2
  end
end

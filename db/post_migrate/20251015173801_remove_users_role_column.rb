# frozen_string_literal: true

class RemoveUsersRoleColumn < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def up
    remove_column :users, :role
  end

  def down
    add_column :users, :role, :smallint
  end
end

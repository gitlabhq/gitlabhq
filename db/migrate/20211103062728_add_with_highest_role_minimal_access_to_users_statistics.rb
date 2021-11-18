# frozen_string_literal: true

class AddWithHighestRoleMinimalAccessToUsersStatistics < Gitlab::Database::Migration[1.0]
  def change
    add_column :users_statistics, :with_highest_role_minimal_access, :integer, null: false, default: 0
  end
end

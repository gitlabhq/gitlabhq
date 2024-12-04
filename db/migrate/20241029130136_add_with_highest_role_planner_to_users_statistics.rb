# frozen_string_literal: true

class AddWithHighestRolePlannerToUsersStatistics < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :users_statistics, :with_highest_role_planner, :integer, default: 0, null: false
  end
end

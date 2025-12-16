# frozen_string_literal: true

class AddWithHighestRoleSecurityManagerToUsersStatistics < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def change
    add_column :users_statistics, :with_highest_role_security_manager, :integer, default: 0, null: false
  end
end

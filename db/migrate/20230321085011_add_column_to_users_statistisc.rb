# frozen_string_literal: true

class AddColumnToUsersStatistisc < Gitlab::Database::Migration[2.1]
  def change
    add_column :users_statistics, :with_highest_role_guest_with_custom_role, :integer, default: 0, null: false
  end
end

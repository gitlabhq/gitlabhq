# frozen_string_literal: true

class AddAccessLevelToOrganizationUsers < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  def change
    add_column :organization_users, :access_level, :integer, default: 10, limit: 2, null: false
  end
end

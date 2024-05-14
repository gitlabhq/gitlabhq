# frozen_string_literal: true

class AddPermissionsToMemberRoles < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  def change
    add_column :member_roles, :permissions, :jsonb, null: false, default: {}
  end
end

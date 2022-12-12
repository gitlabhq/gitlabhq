# frozen_string_literal: true

class AddReadCodeToMemberRoles < Gitlab::Database::Migration[2.1]
  def change
    add_column :member_roles, :read_code, :boolean, default: false
  end
end

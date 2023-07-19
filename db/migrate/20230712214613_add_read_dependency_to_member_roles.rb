# frozen_string_literal: true

class AddReadDependencyToMemberRoles < Gitlab::Database::Migration[2.1]
  def change
    add_column :member_roles, :read_dependency, :boolean, default: false, null: false
  end
end

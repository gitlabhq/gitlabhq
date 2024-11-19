# frozen_string_literal: true

class RemoveNotNullFromMemberRoleBaseAccessLevel < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def up
    change_column_null :member_roles, :base_access_level, true
  end

  def down
    change_column_null :member_roles, :base_access_level, false
  end
end

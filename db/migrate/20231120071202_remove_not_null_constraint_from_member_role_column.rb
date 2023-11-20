# frozen_string_literal: true

class RemoveNotNullConstraintFromMemberRoleColumn < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  def up
    change_column_null :member_roles, :namespace_id, true
  end

  def down
    change_column_null :member_roles, :namespace_id, false
  end
end

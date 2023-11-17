# frozen_string_literal: true

class RemoveNotNullConstraintFromMemberRole < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.6'

  def up
    remove_not_null_constraint :member_roles, :namespace_id
  end

  def down
    add_not_null_constraint :member_roles, :namespace_id
  end
end

# frozen_string_literal: true

class MembersRemoveMemberNamespaceIdNotNullConstraint < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_508774aac0'

  def up
    remove_not_null_constraint :members, :member_namespace_id, constraint_name: CONSTRAINT_NAME
  end

  def down
    add_not_null_constraint :members, :member_namespace_id, validate: false, constraint_name: CONSTRAINT_NAME
  end
end

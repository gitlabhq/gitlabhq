# frozen_string_literal: true

class ValidateNotNullConstraintOnMemberNamespaceId < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_508774aac0'

  def up
    validate_not_null_constraint :members, :member_namespace_id, constraint_name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end

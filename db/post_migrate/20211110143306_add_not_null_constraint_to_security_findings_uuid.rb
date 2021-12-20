# frozen_string_literal: true

class AddNotNullConstraintToSecurityFindingsUuid < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_not_null_constraint(
      :security_findings,
      :uuid,
      validate: false
    )
  end

  def down
    remove_not_null_constraint(
      :security_findings,
      :uuid
    )
  end
end

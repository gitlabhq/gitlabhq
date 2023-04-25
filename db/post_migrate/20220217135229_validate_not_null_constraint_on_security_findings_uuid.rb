# frozen_string_literal: true

class ValidateNotNullConstraintOnSecurityFindingsUuid < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    validate_not_null_constraint(:security_findings, :uuid)
  end

  def down
    # no-op
  end
end

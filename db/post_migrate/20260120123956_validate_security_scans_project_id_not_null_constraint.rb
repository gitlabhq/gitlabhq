# frozen_string_literal: true

class ValidateSecurityScansProjectIdNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  CONSTRAINT_NAME = 'check_2d56d882f6'

  def up
    validate_check_constraint :security_scans, CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end

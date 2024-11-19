# frozen_string_literal: true

class PrepareSecurityScansProjectIdNotNullValidation < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  CONSTRAINT_NAME = 'check_2d56d882f6'

  def up
    prepare_async_check_constraint_validation :security_scans, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :security_scans, name: CONSTRAINT_NAME
  end
end

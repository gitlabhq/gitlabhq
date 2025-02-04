# frozen_string_literal: true

class PrepareNotNullOnVulnerabilitiesDetectedAtValidation < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  CONSTRAINT_NAME = "check_e987357e3b"

  def up
    prepare_async_check_constraint_validation :vulnerabilities, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :vulnerabilities, name: CONSTRAINT_NAME
  end
end

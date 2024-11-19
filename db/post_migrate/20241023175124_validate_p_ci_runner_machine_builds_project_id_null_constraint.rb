# frozen_string_literal: true

class ValidatePCiRunnerMachineBuildsProjectIdNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  TABLE_NAME = :p_ci_runner_machine_builds
  COLUMN_NAME = :project_id
  CONSTRAINT_NAME = :check_149ee35c38

  def up
    validate_not_null_constraint TABLE_NAME, COLUMN_NAME, constraint_name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end

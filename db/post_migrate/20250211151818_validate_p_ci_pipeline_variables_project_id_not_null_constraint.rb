# frozen_string_literal: true

class ValidatePCiPipelineVariablesProjectIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  # Async validation of partitions enqueued in the MR - https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181106

  TABLE_NAME = :p_ci_pipeline_variables
  COLUMN_NAME = :project_id
  CONSTRAINT_NAME = 'check_6e932dbabf'

  def up
    validate_not_null_constraint(TABLE_NAME, COLUMN_NAME, constraint_name: CONSTRAINT_NAME)
  end

  def down
    # no-op
  end
end

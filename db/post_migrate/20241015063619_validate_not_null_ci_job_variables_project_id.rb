# frozen_string_literal: true

class ValidateNotNullCiJobVariablesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  TABLE_NAME = :ci_job_variables
  COLUMN_NAME = :project_id

  def up
    add_not_null_constraint(TABLE_NAME, COLUMN_NAME)
  end

  def down
    remove_not_null_constraint(TABLE_NAME, COLUMN_NAME)

    add_not_null_constraint(TABLE_NAME, COLUMN_NAME, validate: false)
  end
end

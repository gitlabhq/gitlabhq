# frozen_string_literal: true

class AddProjectIdNotNullConstraintToCiStages < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  TABLE_NAME = :p_ci_stages
  COLUMN_NAME = :project_id
  CONSTRAINT_NAME = :check_74835fc631

  def up
    add_not_null_constraint(TABLE_NAME, COLUMN_NAME, constraint_name: CONSTRAINT_NAME, validate: false)
  end

  def down
    remove_not_null_constraint(TABLE_NAME, COLUMN_NAME, constraint_name: CONSTRAINT_NAME)
  end
end

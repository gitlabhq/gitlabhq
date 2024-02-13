# frozen_string_literal: true

class AddStarCountPositiveConstraintToProjects < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.9'

  CONSTRAINT_NAME = 'projects_star_count_positive'
  TABLE = :projects

  def up
    add_check_constraint(TABLE, "star_count >= 0", CONSTRAINT_NAME, validate: false)
    prepare_async_check_constraint_validation(TABLE, name: CONSTRAINT_NAME)
  end

  def down
    unprepare_async_check_constraint_validation(TABLE, name: CONSTRAINT_NAME)
    remove_check_constraint(TABLE, CONSTRAINT_NAME)
  end
end

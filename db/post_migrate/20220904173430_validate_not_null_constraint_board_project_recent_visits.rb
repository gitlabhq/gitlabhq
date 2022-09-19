# frozen_string_literal: true

class ValidateNotNullConstraintBoardProjectRecentVisits < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    validate_not_null_constraint :board_project_recent_visits, :user_id
    validate_not_null_constraint :board_project_recent_visits, :project_id
    validate_not_null_constraint :board_project_recent_visits, :board_id
  end

  def down
    # no-op
  end
end

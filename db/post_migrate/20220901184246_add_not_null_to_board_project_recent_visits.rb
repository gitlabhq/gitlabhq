# frozen_string_literal: true

class AddNotNullToBoardProjectRecentVisits < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_not_null_constraint :board_project_recent_visits, :user_id, validate: false
    add_not_null_constraint :board_project_recent_visits, :project_id, validate: false
    add_not_null_constraint :board_project_recent_visits, :board_id, validate: false
  end

  def down
    remove_not_null_constraint :board_project_recent_visits, :user_id
    remove_not_null_constraint :board_project_recent_visits, :project_id
    remove_not_null_constraint :board_project_recent_visits, :board_id
  end
end

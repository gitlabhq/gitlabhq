# frozen_string_literal: true

class AddNotNullToBoardGroupRecentVisits < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_not_null_constraint :board_group_recent_visits, :user_id, validate: false
    add_not_null_constraint :board_group_recent_visits, :group_id, validate: false
    add_not_null_constraint :board_group_recent_visits, :board_id, validate: false
  end

  def down
    remove_not_null_constraint :board_group_recent_visits, :user_id
    remove_not_null_constraint :board_group_recent_visits, :board_id
    remove_not_null_constraint :board_group_recent_visits, :group_id
  end
end

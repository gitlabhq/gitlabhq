# frozen_string_literal: true

class AddBoardAssigneesShardingKey < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :board_assignees, :group_id, :bigint
    add_column :board_assignees, :project_id, :bigint
  end
end

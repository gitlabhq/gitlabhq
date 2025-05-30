# frozen_string_literal: true

class AddBoardUserPreferenceShardingKey < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    add_column :board_user_preferences, :group_id, :bigint
    add_column :board_user_preferences, :project_id, :bigint
  end
end

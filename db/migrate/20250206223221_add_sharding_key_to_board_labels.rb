# frozen_string_literal: true

class AddShardingKeyToBoardLabels < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :board_labels, :group_id, :bigint
    add_column :board_labels, :project_id, :bigint
  end
end

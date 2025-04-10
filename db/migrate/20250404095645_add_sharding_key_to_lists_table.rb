# frozen_string_literal: true

class AddShardingKeyToListsTable < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :lists, :group_id, :bigint
    add_column :lists, :project_id, :bigint
  end
end

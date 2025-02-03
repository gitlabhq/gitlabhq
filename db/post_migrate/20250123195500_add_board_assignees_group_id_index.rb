# frozen_string_literal: true

class AddBoardAssigneesGroupIdIndex < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_board_assignees_on_group_id'

  disable_ddl_transaction!
  milestone '17.9'

  def up
    add_concurrent_index :board_assignees, :group_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :board_assignees, :group_id, name: INDEX_NAME
  end
end

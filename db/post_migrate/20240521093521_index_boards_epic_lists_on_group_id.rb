# frozen_string_literal: true

class IndexBoardsEpicListsOnGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_boards_epic_lists_on_group_id'

  def up
    add_concurrent_index :boards_epic_lists, :group_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :boards_epic_lists, INDEX_NAME
  end
end

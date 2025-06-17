# frozen_string_literal: true

class AddCustomStatusUniqueIndexToBoardLists < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  CUSTOM_STATUS_INDEX_NAME = 'index_lists_on_board_id_and_custom_status_id'

  def up
    add_concurrent_index :lists, [:board_id, :custom_status_id],
      unique: true, name: CUSTOM_STATUS_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :lists, CUSTOM_STATUS_INDEX_NAME
  end
end

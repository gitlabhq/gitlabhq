# frozen_string_literal: true

class AddSystemDefinedStatusUniqueIndexToBoardLists < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  SYSTEM_DEFINED_INDEX_NAME = 'index_lists_on_board_id_and_system_defined_status_identifier'

  def up
    add_concurrent_index :lists, [:board_id, :system_defined_status_identifier],
      unique: true, name: SYSTEM_DEFINED_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :lists, SYSTEM_DEFINED_INDEX_NAME
  end
end

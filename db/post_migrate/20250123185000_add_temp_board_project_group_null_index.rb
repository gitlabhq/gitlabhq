# frozen_string_literal: true

class AddTempBoardProjectGroupNullIndex < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'tmp_idx_boards_on_project_group_both_missing'

  disable_ddl_transaction!
  milestone '17.9'

  def up
    add_concurrent_index :boards, :id, name: INDEX_NAME, where: 'group_id IS NULL AND project_id IS NULL'
  end

  def down
    remove_concurrent_index :boards, :id, name: INDEX_NAME
  end
end

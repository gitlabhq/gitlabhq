# frozen_string_literal: true

class AddShardingKeyIndexOnDiffNotePositions < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_diff_note_positions_on_namespace_id'

  milestone '18.6'
  disable_ddl_transaction!

  def up
    add_concurrent_index :diff_note_positions, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :diff_note_positions, INDEX_NAME
  end
end

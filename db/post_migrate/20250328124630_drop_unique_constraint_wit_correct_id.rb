# frozen_string_literal: true

class DropUniqueConstraintWitCorrectId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  INDEX_NAME = 'index_work_item_types_on_correct_id_unique'

  def up
    remove_concurrent_index_by_name :work_item_types, INDEX_NAME
  end

  def down
    add_concurrent_index :work_item_types, :correct_id, unique: true, name: INDEX_NAME
  end
end

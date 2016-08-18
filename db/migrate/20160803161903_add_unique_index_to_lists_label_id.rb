class AddUniqueIndexToListsLabelId < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :lists, [:board_id, :label_id], unique: true
  end

  def down
    remove_index :lists, column: [:board_id, :label_id] if index_exists?(:lists, [:board_id, :label_id], unique: true)
  end
end

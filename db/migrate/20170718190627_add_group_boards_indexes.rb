class AddGroupBoardsIndexes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_concurrent_foreign_key :boards, :namespaces, column: :group_id, on_delete: :cascade

    add_concurrent_index :boards, :group_id
  end

  def down
    remove_foreign_key :boards, column: :group_id

    remove_concurrent_index :boards, :group_id
  end
end

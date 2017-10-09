# rubocop:disable RemoveIndex
class AddGroupIdToLabels < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :labels, :group_id, :integer
    add_foreign_key :labels, :namespaces, column: :group_id, on_delete: :cascade # rubocop: disable Migration/AddConcurrentForeignKey
    add_concurrent_index :labels, :group_id
  end

  def down
    remove_foreign_key :labels, column: :group_id
    remove_index :labels, :group_id if index_exists? :labels, :group_id
    remove_column :labels, :group_id
  end
end

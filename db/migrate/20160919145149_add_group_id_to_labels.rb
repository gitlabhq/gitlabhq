class AddGroupIdToLabels < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_column :labels, :group_id, :integer
    add_foreign_key :labels, :namespaces, column: :group_id, on_delete: :cascade
    add_concurrent_index :labels, :group_id
  end
end

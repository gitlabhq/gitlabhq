# rubocop:disable Migration/Datetime
# rubocop:disable RemoveIndex
class AddDeletedAtToNamespaces < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :namespaces, :deleted_at, :datetime

    add_concurrent_index :namespaces, :deleted_at
  end

  def down
    remove_index :namespaces, :deleted_at if index_exists? :namespaces, :deleted_at

    remove_column :namespaces, :deleted_at
  end
end

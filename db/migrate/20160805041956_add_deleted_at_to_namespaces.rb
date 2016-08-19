class AddDeletedAtToNamespaces < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_column :namespaces, :deleted_at, :datetime
    add_concurrent_index :namespaces, :deleted_at
  end
end

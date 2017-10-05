class AddRunnersTokenToGroups < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :namespaces, :runners_token, :string

    add_concurrent_index :namespaces, :runners_token, unique: true
  end

  def down
    remove_column :namespaces, :runners_token
  end
end

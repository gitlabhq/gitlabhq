# Migration type: online without errors (works on previous version and new one)
class AddLdapSyncStateIndicesToGroups < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_concurrent_index :namespaces, :ldap_sync_last_update_at
    add_concurrent_index :namespaces, :ldap_sync_last_successful_update_at
  end

  def down
    remove_index :namespaces, column: :ldap_sync_last_update_at if index_exists?(:namespaces, :ldap_sync_last_update_at)
    remove_index :namespaces, column: :ldap_sync_last_successful_update_at if index_exists?(:namespaces, :ldap_sync_last_successful_update_at)
  end
end

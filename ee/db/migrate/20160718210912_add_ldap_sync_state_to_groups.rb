# Migration type: online without errors (works on previous version and new one)
# rubocop:disable Migration/Datetime
# rubocop:disable Migration/UpdateLargeTable
class AddLdapSyncStateToGroups < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column_with_default :namespaces, :ldap_sync_status, :string, default: 'ready'
    add_column :namespaces, :ldap_sync_error, :string
    add_column :namespaces, :ldap_sync_last_update_at, :datetime
    add_column :namespaces, :ldap_sync_last_successful_update_at, :datetime
    add_column :namespaces, :ldap_sync_last_sync_at, :datetime
  end

  def down
    remove_column :namespaces, :ldap_sync_status
    remove_column :namespaces, :ldap_sync_error
    remove_column :namespaces, :ldap_sync_last_update_at
    remove_column :namespaces, :ldap_sync_last_successful_update_at
    remove_column :namespaces, :ldap_sync_last_sync_at
  end
end

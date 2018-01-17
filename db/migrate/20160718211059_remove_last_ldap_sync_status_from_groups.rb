# Migration type: online without errors (works on previous version and new one)
# rubocop:disable Migration/Datetime
# rubocop:disable Migration/RemoveColumn
class RemoveLastLdapSyncStatusFromGroups < ActiveRecord::Migration
  DOWNTIME = false

  def change
    remove_column :namespaces, :last_ldap_sync_at, :datetime
  end
end

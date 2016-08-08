# Migration type: online without errors (works on previous version and new one)
class RemoveLastLdapSyncStatusFromGroups < ActiveRecord::Migration

  DOWNTIME = false

  def change
    remove_column :namespaces, :last_ldap_sync_at, :datetime
  end
end

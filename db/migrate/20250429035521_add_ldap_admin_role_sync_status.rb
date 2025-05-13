# frozen_string_literal: true

class AddLdapAdminRoleSyncStatus < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.0'

  def up
    with_lock_retries do
      add_column :ldap_admin_role_links, :sync_status, :smallint, null: false, default: 0, if_not_exists: true
      add_column :ldap_admin_role_links, :sync_started_at, :datetime_with_timezone, if_not_exists: true
      add_column :ldap_admin_role_links, :sync_ended_at, :datetime_with_timezone, if_not_exists: true
      add_column :ldap_admin_role_links, :last_successful_sync_at, :datetime_with_timezone, if_not_exists: true
      add_column :ldap_admin_role_links, :sync_error, :text, if_not_exists: true
    end

    add_text_limit :ldap_admin_role_links, :sync_error, 255
  end

  def down
    remove_column :ldap_admin_role_links, :sync_status, if_exists: true
    remove_column :ldap_admin_role_links, :sync_started_at, if_exists: true
    remove_column :ldap_admin_role_links, :sync_ended_at, if_exists: true
    remove_column :ldap_admin_role_links, :last_successful_sync_at, if_exists: true
    remove_column :ldap_admin_role_links, :sync_error, if_exists: true
  end
end

class CleanupUsersLdapEmailRename < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :users, :ldap_email, :external_email
  end

  def down
    # rubocop:disable Migration/UpdateLargeTable
    rename_column_concurrently :users, :external_email, :ldap_email
  end
end

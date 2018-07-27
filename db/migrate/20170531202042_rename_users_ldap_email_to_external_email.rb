class RenameUsersLdapEmailToExternalEmail < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/UpdateLargeTable
    rename_column_concurrently :users, :ldap_email, :external_email
  end

  def down
    cleanup_concurrent_column_rename :users, :external_email, :ldap_email
  end
end

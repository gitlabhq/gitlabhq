class AddRestrictGroupOwnersToAdminsOptionToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings, :allow_group_owners_to_manage_ldap, :boolean, default: true)
  end

  def down
    remove_column(:application_settings, :allow_group_owners_to_manage_ldap)
  end
end

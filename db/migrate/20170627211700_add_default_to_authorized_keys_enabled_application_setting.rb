# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddDefaultToAuthorizedKeysEnabledApplicationSetting < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    change_column :application_settings, :authorized_keys_enabled, :boolean, default: true
    change_column_null :application_settings, :authorized_keys_enabled, false, true
  end

  def down
    change_column_null :application_settings, :authorized_keys_enabled, true
    change_column :application_settings, :authorized_keys_enabled, :boolean, default: nil
  end
end

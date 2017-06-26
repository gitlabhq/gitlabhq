# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddAuthorizedKeysEnabledToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :application_settings, :authorized_keys_enabled, :boolean, default: true, allow_null: false
  end

  def down
    remove_column :application_settings, :authorized_keys_enabled
  end
end

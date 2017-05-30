# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddAuthorizedKeysEnabledToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    # allow_null: true because we want to set the default based on if the
    # instance is configured to use AuthorizedKeysCommand
    add_column :application_settings, :authorized_keys_enabled, :boolean, allow_null: true
  end
end

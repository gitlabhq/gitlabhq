# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddHashedStorageToSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :application_settings, :hashed_storage_enabled, :boolean, default: false
  end

  def down
    remove_columns :application_settings, :hashed_storage_enabled
  end
end

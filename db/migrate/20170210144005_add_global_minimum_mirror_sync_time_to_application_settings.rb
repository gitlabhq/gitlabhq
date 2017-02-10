# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddGlobalMinimumMirrorSyncTimeToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :application_settings,
                            :minimum_mirror_sync_time,
                            :integer,
                            default: 60,
                            allow_null: false
  end

  def down
    remove_column :application_settings, :minimum_mirror_sync_time
  end
end

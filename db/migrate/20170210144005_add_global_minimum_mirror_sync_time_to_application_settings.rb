class AddGlobalMinimumMirrorSyncTimeToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :application_settings,
                            :minimum_mirror_sync_time,
                            :integer,
                            default: 15,
                            allow_null: false
  end

  def down
    remove_column :application_settings, :minimum_mirror_sync_time
  end
end

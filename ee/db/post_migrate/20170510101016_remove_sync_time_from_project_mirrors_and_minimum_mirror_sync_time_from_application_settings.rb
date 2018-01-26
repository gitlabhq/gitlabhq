class RemoveSyncTimeFromProjectMirrorsAndMinimumMirrorSyncTimeFromApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index :projects, [:sync_time] if index_exists? :projects, [:sync_time]
    remove_column :projects, :sync_time, :integer

    remove_column :application_settings, :minimum_mirror_sync_time

    ApplicationSetting.expire
  end

  def down
    add_column :projects, :sync_time, :integer
    add_concurrent_index :projects, [:sync_time]

    add_column_with_default :application_settings,
                            :minimum_mirror_sync_time,
                            :integer,
                            default: 15,
                            allow_null: false
  end
end

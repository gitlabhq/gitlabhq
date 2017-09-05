class AddMissingIndexesToGeoEventLog < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :geo_event_log, :repositories_changed_event_id
    add_concurrent_index :geo_event_log, :repository_deleted_event_id
    add_concurrent_index :geo_event_log, :repository_renamed_event_id
  end

  def down
    remove_concurrent_index :geo_event_log, :repositories_changed_event_id if index_exists? :geo_event_log, :repositories_changed_event_id
    remove_concurrent_index :geo_event_log, :repository_deleted_event_id if index_exists? :geo_event_log, :repository_deleted_event_id
    remove_concurrent_index :geo_event_log, :repository_renamed_event_id if index_exists? :geo_event_log, :repository_renamed_event_id
  end
end

class AddIndexToGeoEventLogRepositoryCreatedEventId < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :geo_event_log, :repository_created_event_id
  end

  def down
    if index_exists? :geo_event_log, :repository_created_event_id
      remove_concurrent_index :geo_event_log, :repository_created_event_id
    end
  end
end

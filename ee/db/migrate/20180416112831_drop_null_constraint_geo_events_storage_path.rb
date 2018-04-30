class DropNullConstraintGeoEventsStoragePath < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  TABLES = %i(geo_hashed_storage_migrated_events geo_repository_created_events
              geo_repository_deleted_events geo_repository_renamed_events)

  def up 
    TABLES.each do |table|
      change_column_null(table, :repository_storage_path, true)
    end
  end

  def down
    TABLES.each do |table|
      change_column_null(table, :repository_storage_path, false)
    end
  end
end

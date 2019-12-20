# frozen_string_literal: true

class AddDesignDiskPathToGeoHashedStorageMigratedEvents < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :geo_hashed_storage_migrated_events, :old_design_disk_path, :text
    add_column :geo_hashed_storage_migrated_events, :new_design_disk_path, :text
  end
end

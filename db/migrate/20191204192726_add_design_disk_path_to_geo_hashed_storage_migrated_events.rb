# frozen_string_literal: true

class AddDesignDiskPathToGeoHashedStorageMigratedEvents < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  def change
    add_column :geo_hashed_storage_migrated_events, :old_design_disk_path, :text
    add_column :geo_hashed_storage_migrated_events, :new_design_disk_path, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end

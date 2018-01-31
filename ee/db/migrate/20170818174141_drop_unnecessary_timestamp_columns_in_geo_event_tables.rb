# rubocop:disable Migration/RemoveColumn
class DropUnnecessaryTimestampColumnsInGeoEventTables < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_column :geo_repository_deleted_events, :created_at
    remove_column :geo_repository_deleted_events, :updated_at
    remove_column :geo_repository_updated_events, :created_at
  end

  def down
    add_column :geo_repository_deleted_events, :created_at, :datetime_with_timezone
    add_column :geo_repository_deleted_events, :updated_at, :datetime_with_timezone
    add_column :geo_repository_updated_events, :created_at, :datetime_with_timezone
  end
end

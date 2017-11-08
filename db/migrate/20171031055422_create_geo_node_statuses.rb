class CreateGeoNodeStatuses < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :geo_node_statuses do |t|
      t.references :geo_node, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.integer :db_replication_lag_seconds
      t.integer :repositories_count
      t.integer :repositories_synced_count
      t.integer :repositories_failed_count
      t.integer :lfs_objects_count
      t.integer :lfs_objects_synced_count
      t.integer :lfs_objects_failed_count
      t.integer :attachments_count
      t.integer :attachments_synced_count
      t.integer :attachments_failed_count
      t.integer :last_event_id
      t.datetime_with_timezone :last_event_date
      t.integer :cursor_last_event_id
      t.datetime_with_timezone :cursor_last_event_date
      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
      t.datetime_with_timezone :last_successful_status_check_at
      t.string :status_message
    end
  end
end

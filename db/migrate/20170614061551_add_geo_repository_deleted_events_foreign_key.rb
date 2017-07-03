class AddGeoRepositoryDeletedEventsForeignKey < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :geo_event_log, :geo_repository_deleted_events,
                               column: :repository_deleted_event_id, on_delete: :cascade
  end

  def down
    remove_foreign_key :geo_event_log, column: :repository_deleted_event_id
  end
end

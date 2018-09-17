# frozen_string_literal: true

class AddGeoResetChecksumEventsForeignKey < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :geo_event_log, :geo_reset_checksum_events,
                               column: :reset_checksum_event_id, on_delete: :cascade
    add_concurrent_index :geo_event_log, :reset_checksum_event_id
  end

  def down
    remove_foreign_key :geo_event_log, column: :reset_checksum_event_id
    remove_concurrent_index :geo_event_log, :reset_checksum_event_id
  end
end

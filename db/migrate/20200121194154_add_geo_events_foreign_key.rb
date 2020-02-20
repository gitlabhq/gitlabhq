# frozen_string_literal: true

class AddGeoEventsForeignKey < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :geo_event_log, :geo_events,
                               column: :geo_event_id,
                               name: 'fk_geo_event_log_on_geo_event_id',
                               on_delete: :cascade
  end

  def down
    remove_foreign_key_without_error :geo_event_log, column: :geo_event_id, name: 'fk_geo_event_log_on_geo_event_id'
  end
end

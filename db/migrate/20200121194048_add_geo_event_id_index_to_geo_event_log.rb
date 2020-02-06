# frozen_string_literal: true

class AddGeoEventIdIndexToGeoEventLog < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :geo_event_log, :geo_event_id,
                         where: "(geo_event_id IS NOT NULL)",
                         using: :btree,
                         name: 'index_geo_event_log_on_geo_event_id'
  end

  def down
    remove_concurrent_index :geo_event_log, :geo_event_id, name: 'index_geo_event_log_on_geo_event_id'
  end
end

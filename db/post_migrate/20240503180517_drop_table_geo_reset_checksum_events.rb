# frozen_string_literal: true

class DropTableGeoResetChecksumEvents < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def up
    drop_table :geo_reset_checksum_events
  end

  def down
    create_table :geo_reset_checksum_events do |t|
      t.integer :project_id, index: { name: 'index_geo_reset_checksum_events_on_project_id' }, null: false
    end
  end
end

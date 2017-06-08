class CreateGeoEventLog < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :geo_event_log, id: :bigserial do |t|
      t.datetime :created_at, null: false
      t.integer :repository_updated_event_id, limit: 8, index: true

      t.foreign_key :geo_repository_updated_events,
        column: :repository_updated_event_id, on_delete: :cascade
    end
  end
end

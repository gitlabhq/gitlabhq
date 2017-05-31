class CreateGeoEventLog < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :geo_event_log, id: :bigserial do |t|
      t.datetime :created_at, index: true, null: false
      t.integer :push_event_id, index: true

      t.foreign_key :geo_push_events, column: :push_event_id, on_delete: :cascade
    end
  end
end

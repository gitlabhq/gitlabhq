class CreateGeoEventLog < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :geo_event_log do |t|
      t.datetime :created_at, index: true, null: false
      t.integer :push_event_id, index: true
    end

    add_foreign_key :geo_event_log, :geo_push_events, column: :push_event_id, on_delete: :cascade # rubocop: disable Migration/AddConcurrentForeignKey
  end
end

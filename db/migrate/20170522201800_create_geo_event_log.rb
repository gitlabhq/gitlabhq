class CreateGeoEventLog < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :geo_event_log do |t|
      t.integer :push_event_id
      t.datetime :created_at, index: true, null: false
    end

    add_foreign_key :geo_event_log, :geo_push_events, column: :push_event_id, on_delete: :cascade # rubocop: disable Migration/AddConcurrentForeignKey
    add_index :geo_event_log, :push_event_id
  end
end

class CreateGeoPushEvents < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :geo_push_events do |t|
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.datetime :created_at, null: false
      t.integer :event_type, limit: 2, index: true, null: false
    end
  end
end

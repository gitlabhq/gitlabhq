class CreateGeoPushEvents < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :geo_push_events do |t|
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.datetime :created_at, null: false
      t.string :ref
      t.integer :branches_affected, null: false
      t.integer :tags_affected, null: false
      t.boolean :new_branch, default: false, null: false
      t.boolean :remove_branch, default: false, null: false
    end
  end
end

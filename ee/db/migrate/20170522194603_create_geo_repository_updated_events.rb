class CreateGeoRepositoryUpdatedEvents < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :geo_repository_updated_events, id: :bigserial do |t|
      t.datetime :created_at, null: false
      t.integer :branches_affected, null: false
      t.integer :tags_affected, null: false
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.integer :source, limit: 2, index: true, null: false
      t.boolean :new_branch, default: false, null: false
      t.boolean :remove_branch, default: false, null: false
      t.text :ref
    end
  end
end

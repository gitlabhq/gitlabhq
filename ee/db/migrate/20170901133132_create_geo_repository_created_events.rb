class CreateGeoRepositoryCreatedEvents < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :geo_repository_created_events, id: :bigserial do |t|
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.text :repository_storage_name, null: false
      t.text :repository_storage_path, null: false
      t.text :repo_path, null: false
      t.text :wiki_path
      t.text :project_name, null: false
    end

    add_column :geo_event_log, :repository_created_event_id, :integer, limit: 8
  end
end

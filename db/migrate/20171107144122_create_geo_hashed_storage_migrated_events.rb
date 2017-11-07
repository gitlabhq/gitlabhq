class CreateGeoHashedStorageMigratedEvents < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :geo_hashed_storage_migrated_events, id: :bigserial do |t|
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.text :repository_storage_name, null: false
      t.text :repository_storage_path, null: false
      t.text :old_disk_path, null: false
      t.text :new_disk_path, null: false
      t.text :old_wiki_disk_path, null: false
      t.text :new_wiki_disk_path, null: false
      t.integer :old_storage_version, limit: 2
      t.integer :new_storage_version, null: false, limit: 2
    end

    add_column :geo_event_log, :hashed_storage_migrated_event_id, :integer, limit: 8
  end
end

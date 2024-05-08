# frozen_string_literal: true

class DropTableGeoHashedStorageMigratedEvents < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def up
    drop_table :geo_hashed_storage_migrated_events
  end

  def down
    create_table :geo_hashed_storage_migrated_events do |t|
      t.integer :project_id, index: { name: 'index_geo_hashed_storage_migrated_events_on_project_id' }, null: false
      t.text :repository_storage_name, null: false
      t.text :old_disk_path, null: false
      t.text :new_disk_path, null: false
      t.text :old_wiki_disk_path, null: false
      t.text :new_wiki_disk_path, null: false
      t.integer :old_storage_version, limit: 2
      t.integer :new_storage_version, limit: 2, null: false
      t.text :old_design_disk_path
      t.text :new_design_disk_path
    end
  end
end

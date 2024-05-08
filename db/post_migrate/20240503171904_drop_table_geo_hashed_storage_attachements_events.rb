# frozen_string_literal: true

class DropTableGeoHashedStorageAttachementsEvents < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def up
    drop_table :geo_hashed_storage_attachments_events
  end

  def down
    create_table :geo_hashed_storage_attachments_events do |t|
      t.integer :project_id, index: { name: 'index_geo_hashed_storage_attachments_events_on_project_id' }, null: false
      t.text :old_attachments_path, null: false
      t.text :new_attachments_path, null: false
    end
  end
end

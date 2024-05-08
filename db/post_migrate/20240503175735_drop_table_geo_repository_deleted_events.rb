# frozen_string_literal: true

class DropTableGeoRepositoryDeletedEvents < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def up
    drop_table :geo_repository_deleted_events
  end

  def down
    create_table :geo_repository_deleted_events do |t|
      t.integer :project_id, index: { name: 'index_geo_repository_deleted_events_on_project_id' }, null: false
      t.text :repository_storage_name, null: false
      t.text :deleted_path, null: false
      t.text :deleted_wiki_path
      t.text :deleted_project_name, null: false
    end
  end
end

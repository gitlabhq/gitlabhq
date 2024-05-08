# frozen_string_literal: true

class DropTableGeoRepositoryCreatedEvents < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def up
    drop_table :geo_repository_created_events
  end

  def down
    create_table :geo_repository_created_events do |t|
      t.integer :project_id, index: { name: 'index_geo_repository_created_events_on_project_id' }, null: false
      t.text :repository_storage_name, null: false
      t.text :repo_path, null: false
      t.text :wiki_path
      t.text :project_name, null: false
    end
  end
end

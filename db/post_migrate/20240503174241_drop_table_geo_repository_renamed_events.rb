# frozen_string_literal: true

class DropTableGeoRepositoryRenamedEvents < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def up
    drop_table :geo_repository_renamed_events
  end

  def down
    create_table :geo_repository_renamed_events do |t|
      t.integer :project_id, index: { name: 'index_geo_repository_renamed_events_on_project_id' }, null: false
      t.text :repository_storage_name, null: false
      t.text :old_path_with_namespace, null: false
      t.text :new_path_with_namespace, null: false
      t.text :old_wiki_path_with_namespace, null: false
      t.text :new_wiki_path_with_namespace, null: false
      t.text :old_path, null: false
      t.text :new_path, null: false
    end
  end
end

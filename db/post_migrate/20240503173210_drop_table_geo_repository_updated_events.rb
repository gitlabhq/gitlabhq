# frozen_string_literal: true

class DropTableGeoRepositoryUpdatedEvents < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def up
    drop_table :geo_repository_updated_events
  end

  def down
    create_table :geo_repository_updated_events do |t|
      t.integer :branches_affected, null: false
      t.integer :tags_affected, null: false
      t.integer :project_id, index: { name: 'index_geo_repository_updated_events_on_project_id' }, null: false
      t.integer :source, limit: 2, index: { name: 'index_geo_repository_updated_events_on_source' }, null: false
      t.boolean :new_branch, default: false, null: false
      t.boolean :remove_branch, default: false, null: false
      t.text :ref
    end
  end
end

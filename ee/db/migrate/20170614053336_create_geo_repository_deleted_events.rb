class CreateGeoRepositoryDeletedEvents < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :geo_repository_deleted_events, id: :bigserial do |t|
      # If a project is deleted, we need to retain this entry
      t.references :project, index: true, foreign_key: false, null: false
      t.text :repository_storage_name, null: false
      t.text :repository_storage_path, null: false
      t.text :deleted_path, null: false
      t.text :deleted_wiki_path
      t.text :deleted_project_name, null: false
    end

    add_timestamps_with_timezone :geo_repository_deleted_events
    add_column :geo_event_log, :repository_deleted_event_id, :integer, limit: 8
  end
end

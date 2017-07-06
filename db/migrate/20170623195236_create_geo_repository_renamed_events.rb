class CreateGeoRepositoryRenamedEvents < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :geo_repository_renamed_events, id: :bigserial do |t|
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.text :repository_storage_name, null: false
      t.text :repository_storage_path, null: false
      t.text :old_path_with_namespace, null: false
      t.text :new_path_with_namespace, null: false
      t.text :old_wiki_path_with_namespace, null: false
      t.text :new_wiki_path_with_namespace, null: false
      t.text :old_path, null: false
      t.text :new_path, null: false
    end

    add_column :geo_event_log, :repository_renamed_event_id, :integer, limit: 8
  end
end

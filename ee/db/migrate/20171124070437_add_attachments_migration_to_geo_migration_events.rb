# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddAttachmentsMigrationToGeoMigrationEvents < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :geo_hashed_storage_attachments_events, id: :bigserial do |t|
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.text :old_attachments_path, null: false
      t.text :new_attachments_path, null: false
    end

    add_column :geo_event_log, :hashed_storage_attachments_event_id, :integer, limit: 8
  end
end

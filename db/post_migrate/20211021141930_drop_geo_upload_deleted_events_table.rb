# frozen_string_literal: true

class DropGeoUploadDeletedEventsTable < Gitlab::Database::Migration[1.0]
  def up
    drop_table :geo_upload_deleted_events
  end

  def down
    create_table :geo_upload_deleted_events, id: :bigserial do |t|
      t.integer :upload_id, null: false, index: true
      t.string :file_path, null: false
      t.integer :model_id, null: false
      t.string :model_type, null: false
      t.string :uploader, null: false
    end
  end
end

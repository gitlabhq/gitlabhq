class CreateGeoUploadDeletedEvents < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :geo_upload_deleted_events, id: :bigserial do |t|
      # If an upload is deleted, we need to retain this entry
      t.references :upload, index: true, foreign_key: false, null: false
      t.string :file_path, null: false
      t.integer :model_id, null: false
      t.string :model_type, null: false
      t.string :uploader, null: false
    end

    add_column :geo_event_log, :upload_deleted_event_id, :integer, limit: 8
  end
end

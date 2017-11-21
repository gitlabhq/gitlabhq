class CreateGeoLfsObjectDeletedEvents < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :geo_lfs_object_deleted_events, id: :bigserial do |t|
      # If a LFS object is deleted, we need to retain this entry
      t.references :lfs_object, index: true, foreign_key: false, null: false
      t.string :oid, null: false
      t.string :file_path, null: false
    end

    add_column :geo_event_log, :lfs_object_deleted_event_id, :integer, limit: 8
  end
end

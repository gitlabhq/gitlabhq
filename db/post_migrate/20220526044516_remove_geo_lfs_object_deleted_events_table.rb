# frozen_string_literal: true

class RemoveGeoLfsObjectDeletedEventsTable < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    drop_table :geo_lfs_object_deleted_events
  end

  def down
    create_table :geo_lfs_object_deleted_events, id: :bigserial do |t|
      t.integer :lfs_object_id, null: false, index: true
      t.string :oid, null: false
      t.string :file_path, null: false
    end
  end
end

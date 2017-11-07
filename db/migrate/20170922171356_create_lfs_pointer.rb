class CreateLfsPointer < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    create_table :lfs_pointers do |t|
      t.references :project, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.string :blob_oid, null: false
      t.string :lfs_oid, null: false
      t.index :blob_oid # Used to filter on removed blobs
    end

    add_index "lfs_pointers", %w[project_id blob_oid], name: "index_lfs_pointers_on_project_id_and_blob_oid", unique: true, using: :btree
  end
end

class CreateLfsFileLocks < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :lfs_file_locks do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.datetime :created_at, null: false
      t.string :path, limit: 511
    end

    add_index :lfs_file_locks, [:project_id, :path], unique: true
  end
end

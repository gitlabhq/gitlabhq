class CreateLfsFileLocks < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :lfs_file_locks do |t|
      t.references :project, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.string :path
      t.datetime :created_at, null: false
    end

    add_index :lfs_file_locks, [:path, :project_id], unique: true
  end
end

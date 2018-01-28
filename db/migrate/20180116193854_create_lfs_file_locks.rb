class CreateLfsFileLocks < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :lfs_file_locks do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.datetime :created_at, null: false
      t.string :path, limit: 511
    end

    add_index :lfs_file_locks, [:project_id, :path], unique: true
  end

  def down
    if foreign_keys_for(:lfs_file_locks, :project_id).any?
      remove_foreign_key :lfs_file_locks, column: :project_id
    end

    if index_exists?(:lfs_file_locks, [:project_id, :path])
      remove_concurrent_index :lfs_file_locks, [:project_id, :path]
    end

    drop_table :lfs_file_locks
  end
end

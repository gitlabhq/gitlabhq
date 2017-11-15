# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class TrackUntrackedUploads < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false
  MIGRATION = 'PrepareUntrackedUploads'

  def up
    unless table_exists?(:untracked_files_for_uploads)
      create_table :untracked_files_for_uploads do |t|
        t.string :path, limit: 600, null: false
        t.boolean :tracked, default: false, null: false
        t.timestamps_with_timezone null: false
      end
    end

    unless index_exists?(:untracked_files_for_uploads, :path)
      add_index :untracked_files_for_uploads, :path, unique: true
    end

    unless index_exists?(:untracked_files_for_uploads, :tracked)
      add_index :untracked_files_for_uploads, :tracked
    end

    BackgroundMigrationWorker.perform_async(MIGRATION)
  end

  def down
    if table_exists?(:untracked_files_for_uploads)
      drop_table :untracked_files_for_uploads
    end
  end
end

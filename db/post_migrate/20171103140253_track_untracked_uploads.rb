# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class TrackUntrackedUploads < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false
  MIGRATION = 'PrepareUnhashedUploads'

  def up
    unless table_exists?(:unhashed_upload_files)
      create_table :unhashed_upload_files do |t|
        t.string :path, null: false
        t.boolean :tracked, default: false, null: false
        t.timestamps_with_timezone null: false
      end
    end

    unless index_exists?(:unhashed_upload_files, :path)
      add_index :unhashed_upload_files, :path, unique: true
    end

    unless index_exists?(:unhashed_upload_files, :tracked)
      add_index :unhashed_upload_files, :tracked
    end

    BackgroundMigrationWorker.perform_async(MIGRATION)
  end

  def down
    if table_exists?(:unhashed_upload_files)
      drop_table :unhashed_upload_files
    end
  end
end

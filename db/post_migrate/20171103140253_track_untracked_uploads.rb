# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class TrackUntrackedUploads < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false
  MIGRATION = 'PrepareUntrackedUploads'

  def up
    BackgroundMigrationWorker.perform_async(MIGRATION)
  end

  def down
    if table_exists?(:untracked_files_for_uploads)
      drop_table :untracked_files_for_uploads
    end
  end
end

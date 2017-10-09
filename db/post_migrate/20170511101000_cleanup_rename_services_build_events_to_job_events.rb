# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CleanupRenameServicesBuildEventsToJobEvents < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :services, :build_events, :job_events
  end

  def down
    rename_column_concurrently :services, :job_events, :build_events
  end
end

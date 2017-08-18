# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CleanupRenameWebHooksBuildEventsToJobEvents < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :web_hooks, :build_events, :job_events
  end

  def down
    rename_column_concurrently :web_hooks, :job_events, :build_events
  end
end

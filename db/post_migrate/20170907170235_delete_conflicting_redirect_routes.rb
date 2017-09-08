# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DeleteConflictingRedirectRoutes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'DeleteConflictingRedirectRoutesRange'.freeze

  disable_ddl_transaction!

  class Route < ActiveRecord::Base
    include EachBatch

    self.table_name = 'routes'
  end

  def up
    say opening_message

    queue_background_migration_jobs_by_range(Route, MIGRATION)
  end

  def down
    # nothing
  end

  def opening_message
    <<~MSG
      Clean up redirect routes that conflict with regular routes.
         See initial bug fix:
         https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/13357
    MSG
  end
end

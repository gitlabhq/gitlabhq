# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ScheduleFixingNamesOfUserNamespaces < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  class Namespace < ActiveRecord::Base
    include ::EachBatch

    self.table_name = 'namespaces'

    scope :user_namespaces, -> { where(type: nil) }
  end

  class Route < ActiveRecord::Base
    include ::EachBatch

    self.table_name = 'routes'

    scope :project_routes, -> { where(source_type: 'Project') }
  end

  disable_ddl_transaction!

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      ScheduleFixingNamesOfUserNamespaces::Namespace.user_namespaces,
      'FixUserNamespaceNames',
      60.seconds,
      batch_size: 5000
    )

    queue_background_migration_jobs_by_range_at_intervals(
      ScheduleFixingNamesOfUserNamespaces::Route.project_routes,
      'FixUserProjectRouteNames',
      60.seconds,
      batch_size: 5000
    )
  end

  def down
    # no-op
  end
end

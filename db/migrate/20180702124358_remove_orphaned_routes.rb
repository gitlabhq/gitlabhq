# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveOrphanedRoutes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Route < ActiveRecord::Base
    self.table_name = 'routes'
    include EachBatch

    def self.orphaned_namespace_routes
      where(source_type: 'Namespace')
        .where('NOT EXISTS ( SELECT 1 FROM namespaces WHERE namespaces.id = routes.source_id )')
    end

    def self.orphaned_project_routes
      where(source_type: 'Project')
        .where('NOT EXISTS ( SELECT 1 FROM projects WHERE projects.id = routes.source_id )')
    end
  end

  def up
    # Some of these queries can take up to 10 seconds to run on GitLab.com,
    # which is pretty close to our 15 second statement timeout. To ensure a
    # smooth deployment procedure we disable the statement timeouts for this
    # migration, just in case.
    disable_statement_timeout

    # On GitLab.com there are around 4000 orphaned project routes, and around
    # 150 orphaned namespace routes.
    [
      Route.orphaned_project_routes,
      Route.orphaned_namespace_routes
    ].each do |relation|
      relation.each_batch(of: 1_000) do |batch|
        batch.delete_all
      end
    end
  end

  def down
    # There is no way to restore orphaned routes, and this doesn't make any
    # sense anyway.
  end
end

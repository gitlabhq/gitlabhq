# Follow up of CleanupNamespacelessPendingDeleteProjects and it cleans
# all projects with `pending_delete = true` and for which the
# namespace no longer exists.
class CleanupNonexistingNamespacePendingDeleteProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Project < ActiveRecord::Base
    self.table_name = 'projects'

    include ::EachBatch
  end

  class Namespace < ActiveRecord::Base
    self.table_name = 'namespaces'
  end

  def up
    find_projects.each_batch do |batch|
      args = batch.pluck(:id).map { |id| [id] }

      NamespacelessProjectDestroyWorker.bulk_perform_async(args)
    end
  end

  def down
    # NOOP
  end

  private

  def find_projects
    projects = Project.arel_table
    namespaces = Namespace.arel_table

    namespace_query = namespaces.project(1)
                        .where(namespaces[:id].eq(projects[:namespace_id]))
                        .exists.not

    # SELECT "projects"."id"
    # FROM "projects"
    # WHERE "projects"."pending_delete" = 't'
    #   AND (NOT (EXISTS
    #               (SELECT 1
    #                FROM "namespaces"
    #                WHERE "namespaces"."id" = "projects"."namespace_id")))
    Project.where(projects[:pending_delete].eq(true))
      .where(namespace_query)
      .select(:id)
  end
end

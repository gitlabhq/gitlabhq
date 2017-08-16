# Follow up of CleanupNamespacelessPendingDeleteProjects and it cleans
# all projects with `pending_delete = true` and for which the
# namespace no longer exists.
class CleanupNonexistingNamespacePendingDeleteProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    @offset = 0

    loop do
      ids = pending_delete_batch

      break if ids.empty?

      args = ids.map { |id| Array(id) }

      NamespacelessProjectDestroyWorker.bulk_perform_async(args)

      @offset += 1
    end
  end

  def down
    # noop
  end

  private

  def pending_delete_batch
    connection.exec_query(find_batch).map { |row| row['id'].to_i }
  end

  BATCH_SIZE = 5000

  def find_batch
    projects = Project.arel_table
    namespaces = Namespace.arel_table

    namespace_query = namespaces.project(1)
                        .where(namespaces[:id].eq(projects[:namespace_id]))
                        .exists.not

    projects.project(projects[:id])
      .where(projects[:pending_delete].eq(true))
      .where(namespace_query)
      .skip(@offset * BATCH_SIZE)
      .take(BATCH_SIZE)
      .to_sql
  end
end

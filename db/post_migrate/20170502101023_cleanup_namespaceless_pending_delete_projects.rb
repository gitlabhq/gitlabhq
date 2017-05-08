# This is the counterpart of RequeuePendingDeleteProjects and cleans all
# projects with `pending_delete = true` and that do not have a namespace.
class CleanupNamespacelessPendingDeleteProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    admin = User.find_by(admin: true)
    return unless admin

    @offset = 0

    loop do
      ids = pending_delete_batch

      break if ids.rows.count.zero?

      args = ids.map { |id| [id['id'], admin.id, {}] }

      NamespacelessProjectDestroyWorker.bulk_perform_async(args)

      @offset += 1
    end
  end

  def down
    # noop
  end

  private

  def pending_delete_batch
    connection.exec_query(find_batch)
  end

  BATCH_SIZE = 5000

  def find_batch
    projects = Arel::Table.new(:projects)
    projects.project(projects[:id]).
      where(projects[:pending_delete].eq(true)).
      where(projects[:namespace_id].eq(nil)).
      skip(@offset * BATCH_SIZE).
      take(BATCH_SIZE).
      to_sql
  end
end

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RequeuePendingDeleteProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    admin = User.find_by(admin: true)
    return unless admin

    @offset = 0

    loop do
      ids = pending_delete_batch

      break if ids.rows.count.zero?

      args = ids.map { |id| [id['id'], admin.id, {}] }

      Sidekiq::Client.push_bulk('class' => "ProjectDestroyWorker", 'args' => args)

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
    projects.project(projects[:id])
      .where(projects[:pending_delete].eq(true))
      .where(projects[:namespace_id].not_eq(nil))
      .skip(@offset * BATCH_SIZE)
      .take(BATCH_SIZE)
      .to_sql
  end
end

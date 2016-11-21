class DeleteSoftDeletedEntities < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  BATCH_SIZE = 128
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    [namespaces_sql, projects_sql].each do |sql|
      loop do
        deleted = connection.exec_query(sql)

        break if deleted.rows.count.zero?

        sleep(100)
      end
    end
  end

  def down
    # Noop
  end

  def namespaces_sql
    namespaces = Arel::Table.new(:namespaces)
    Arel::DeleteManager.new(ActiveRecord::Base).  
      from(namespaces).
      where(namespaces[:id].in(
        namespaces.project(namespaces[:id]).
        where(namespaces[:deleted_at].not_eq(nil)).
        take(BATCH_SIZE))
      ).
      to_sql
  end

  def projects_sql
    projects = Arel::Table.new(:projects)
    Arel::DeleteManager.new(ActiveRecord::Base).
      from(projects).
      where(projects[:id].in(
        projects.project(projects[:id]).
        where(projects[:pending_delete].eq(true)).
        take(BATCH_SIZE))
      ).
      to_sql
  end
end

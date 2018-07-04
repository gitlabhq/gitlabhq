class FixProjectRecordsWithInvalidVisibility < ActiveRecord::Migration
  include Gitlab::Database::ArelMethods
  include Gitlab::Database::MigrationHelpers

  BATCH_SIZE = 500
  DOWNTIME = false

  # This migration is idempotent and there's no sense in throwing away the
  # partial result if it's interrupted
  disable_ddl_transaction!

  def up
    projects = Arel::Table.new(:projects)
    namespaces = Arel::Table.new(:namespaces)

    finder_sql =
      projects
        .join(namespaces, Arel::Nodes::InnerJoin)
        .on(projects[:namespace_id].eq(namespaces[:id]))
        .where(projects[:visibility_level].gt(namespaces[:visibility_level]))
        .project(projects[:id], namespaces[:visibility_level])
        .take(BATCH_SIZE)
        .to_sql

    # Update matching rows in batches. Each batch can cause up to 3 UPDATE
    # statements, in addition to the SELECT: one per visibility_level
    loop do
      to_update = connection.exec_query(finder_sql)
      break if to_update.rows.count == 0

      # row[0] is projects.id, row[1] is namespaces.visibility_level
      updates = to_update.rows.each_with_object(Hash.new {|h, k| h[k] = [] }) do |row, obj|
        obj[row[1]] << row[0]
      end

      updates.each do |visibility_level, project_ids|
        updater = arel_update_manager
          .table(projects)
          .set(projects[:visibility_level] => visibility_level)
          .where(projects[:id].in(project_ids))

        ActiveRecord::Base.connection.exec_update(updater.to_sql, self.class.name, [])
      end
    end
  end

  def down
    # no-op
  end
end

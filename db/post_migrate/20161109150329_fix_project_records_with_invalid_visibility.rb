class FixProjectRecordsWithInvalidVisibility < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  BATCH_SIZE = 1000
  DOWNTIME = false

  # This migration is idempotent and there's no sense in throwing away the
  # partial result if it's interrupted
  disable_ddl_transaction!

  def up
    projects = Arel::Table.new(:projects)
    namespaces = Arel::Table.new(:namespaces)

    finder =
      projects.
      join(namespaces, Arel::Nodes::InnerJoin).
      on(projects[:namespace_id].eq(namespaces[:id])).
      where(projects[:visibility_level].gt(namespaces[:visibility_level])).
      project(projects[:id]).
      take(BATCH_SIZE)

    # MySQL requires a derived table to perform this query
    nested_finder =
      projects.
      from(finder.as("AS projects_inner")).
      project(projects[:id])

    valuer =
      namespaces.
      where(namespaces[:id].eq(projects[:namespace_id])).
      project(namespaces[:visibility_level])

    # Update matching rows until none remain. The finder contains a limit.
    loop do
      updater = Arel::UpdateManager.new(ActiveRecord::Base).
        table(projects).
        set(projects[:visibility_level] => Arel::Nodes::SqlLiteral.new("(#{valuer.to_sql})")).
        where(projects[:id].in(nested_finder))

      num_updated = connection.exec_update(updater.to_sql, self.class.name, [])
      break if num_updated == 0
    end
  end

  def down
    # no-op
  end
end

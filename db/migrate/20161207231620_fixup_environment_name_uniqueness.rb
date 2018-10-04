class FixupEnvironmentNameUniqueness < ActiveRecord::Migration
  include Gitlab::Database::ArelMethods
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'Renaming non-unique environments'

  def up
    environments = Arel::Table.new(:environments)

    # Get all [project_id, name] pairs that occur more than once
    finder_sql = environments
      .group(environments[:project_id], environments[:name])
      .having(Arel.sql("COUNT(1)").gt(1))
      .project(environments[:project_id], environments[:name])
      .to_sql

    conflicting = connection.exec_query(finder_sql)

    conflicting.rows.each do |project_id, name|
      fix_duplicates(project_id, name)
    end
  end

  def down
    # Nothing to do
  end

  # Rename conflicting environments by appending "-#{id}" to all but the first
  def fix_duplicates(project_id, name)
    environments = Arel::Table.new(:environments)
    finder_sql = environments
      .where(environments[:project_id].eq(project_id))
      .where(environments[:name].eq(name))
      .order(environments[:id].asc)
      .project(environments[:id], environments[:name])
      .to_sql

    # Now we have the data for all the conflicting rows
    conflicts = connection.exec_query(finder_sql).rows
    conflicts.shift # Leave the first row alone

    conflicts.each do |id, name|
      update_sql =
        arel_update_manager
          .table(environments)
          .set(environments[:name] => name + "-" + id.to_s)
          .where(environments[:id].eq(id))
          .to_sql

      connection.exec_update(update_sql, self.class.name, [])
    end
  end
end

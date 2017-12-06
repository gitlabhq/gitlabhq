# rubocop:disable Migration/UpdateLargeTable
class UpdateRetriedForCiBuild < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    disable_statement_timeout

    if Gitlab::Database.mysql?
      up_mysql
    else
      up_postgres
    end
  end

  def down
  end

  private

  def up_mysql
    # This is a trick to overcome MySQL limitation:
    # Mysql2::Error: Table 'ci_builds' is specified twice, both as a target for 'UPDATE' and as a separate source for data
    # However, this leads to create a temporary table from `max(ci_builds.id)` which is slow and do full database update
    execute <<-SQL.strip_heredoc
      UPDATE ci_builds SET retried=
        (id NOT IN (
          SELECT * FROM (SELECT MAX(ci_builds.id) FROM ci_builds GROUP BY commit_id, name) AS latest_jobs
        ))
      WHERE retried IS NULL
    SQL
  end

  def up_postgres
    with_temporary_partial_index do
      latest_id = <<-SQL.strip_heredoc
        SELECT MAX(ci_builds2.id)
          FROM ci_builds ci_builds2
          WHERE ci_builds.commit_id=ci_builds2.commit_id
            AND ci_builds.name=ci_builds2.name
      SQL

      # This is slow update as it does single-row query
      # This is designed to be run as idle, or a post deployment migration
      is_retried = Arel.sql("((#{latest_id}) != ci_builds.id)")

      update_column_in_batches(:ci_builds, :retried, is_retried) do |table, query|
        query.where(table[:retried].eq(nil))
      end
    end
  end

  def with_temporary_partial_index
    if Gitlab::Database.postgresql?
      unless index_exists?(:ci_builds, :id, name: :index_for_ci_builds_retried_migration)
        execute 'CREATE INDEX CONCURRENTLY index_for_ci_builds_retried_migration ON ci_builds (id) WHERE retried IS NULL;'
      end
    end

    yield

    if Gitlab::Database.postgresql? && index_exists?(:ci_builds, :id, name: :index_for_ci_builds_retried_migration)
      execute 'DROP INDEX CONCURRENTLY index_for_ci_builds_retried_migration'
    end
  end
end

class UpateRetriedForCiBuild < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    disable_statement_timeout

    with_temporary_partial_index do
      update_column_in_batches(:ci_builds, :retried, &method(:retried_query)) do |table, query|
        query = query.where(table[:retried].eq(nil))
      end
    end
  end

  def down
  end

  private

  def retried_query(table, query, start_id, stop_id)
    latest_commits = <<-SQL.strip_heredoc
      SELECT DISTINCT ci_builds3.commit_id
        FROM ci_builds3
        WHERE #{start_id} <= id
    SQL

    latest_commits = "#{latest_commits} AND id < #{stop_id}" if stop_id

    latest_ids = <<-SQL.strip_heredoc
      SELECT MAX(ci_builds2.id) FROM ci_builds2
        WHERE commit_id IN (#{latest_commits})
        GROUP BY commit_id, name
    SQL

    latest_ids = <<-SQL.strip_heredoc
      SELECT * FROM (#{latest_ids}) AS latest_ids
    SQL

    value = Arel.sql("(ci_builds.id NOT IN (#{latest_ids}))")
    
    query.set([[table[:retried], value]])
  end

  def with_temporary_partial_index
    if Gitlab::Database.postgresql?
      execute 'CREATE INDEX CONCURRENTLY IF NOT EXISTS index_for_ci_builds_retried_migration ON ci_builds (id) WHERE retried IS NULL;'
    end

    yield

    if Gitlab::Database.postgresql?
      execute 'DROP INDEX CONCURRENTLY IF EXISTS index_for_ci_builds_retried_migration'
    end
  end
end

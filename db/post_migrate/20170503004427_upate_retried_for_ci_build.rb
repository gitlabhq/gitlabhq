class UpateRetriedForCiBuild < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  
  disable_ddl_transaction!

  def up
    disable_statement_timeout

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

  def down
  end
end

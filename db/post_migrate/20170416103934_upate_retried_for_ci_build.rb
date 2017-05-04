# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UpateRetriedForCiBuild < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false
  
  disable_ddl_transaction!

  def up
    disable_statement_timeout

    latest_id = <<-SQL.trip_heredoc
      SELECT MAX(ci_builds2.id)
        FROM ci_builds ci_builds2
        WHERE ci_builds.commit_id=ci_builds2.commit_id
          AND ci_builds.name=ci_builds2.name
    SQL

    update_column_in_batches(:ci_builds, :retried, false) do |table, query|
      query.where.not(table[:retried].eq(true))
        .where("ci_builds.id = (#{latest_id})")
    end
  end

  def down
  end
end

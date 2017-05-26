class MigratePipelineStages < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    disable_statement_timeout

    execute <<-SQL.strip_heredoc
      INSERT INTO ci_stages (project_id, pipeline_id, name)
        SELECT project_id, commit_id, stage FROM ci_builds
          WHERE stage IS NOT NULL
          GROUP BY project_id, commit_id, stage, stage_idx
          ORDER BY stage_idx
    SQL
  end

  def down
    execute('TRUNCATE TABLE ci_stages')
  end
end

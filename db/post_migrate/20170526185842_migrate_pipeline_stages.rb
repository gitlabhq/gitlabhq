class MigratePipelineStages < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    disable_statement_timeout(transaction: false) do
      execute <<-SQL.strip_heredoc
        INSERT INTO ci_stages (project_id, pipeline_id, name)
          SELECT project_id, commit_id, stage FROM ci_builds
            WHERE stage IS NOT NULL
            AND stage_id IS NULL
            AND EXISTS (SELECT 1 FROM projects WHERE projects.id = ci_builds.project_id)
            AND EXISTS (SELECT 1 FROM ci_pipelines WHERE ci_pipelines.id = ci_builds.commit_id)
            GROUP BY project_id, commit_id, stage
            ORDER BY MAX(stage_idx)
      SQL
    end
  end
end

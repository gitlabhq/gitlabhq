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

    add_column(:ci_builds, :stage_id, :integer)

    stage_id = Arel.sql('(SELECT id FROM ci_stages ' \
                         'WHERE ci_stages.pipeline_id = ci_builds.commit_id ' \
                         'AND ci_stages.name = ci_builds.stage)')
    update_column_in_batches(:ci_builds, :stage_id, stage_id)

    # add_concurrent_foreign_key :ci_stages, :projects, column: :project_id, on_delete: :cascade
    # add_concurrent_foreign_key :ci_builds, :ci_stages, column: :stage_id, on_delete: :cascade
  end

  def down
    execute('TRUNCATE TABLE ci_stages')
  end
end

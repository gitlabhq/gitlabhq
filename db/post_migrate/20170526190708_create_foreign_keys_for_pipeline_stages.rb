class CreateForeignKeysForPipelineStages < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    execute <<~SQL
      DELETE FROM ci_stages
        WHERE NOT EXISTS (
          SELECT true FROM projects
            WHERE projects.id = ci_stages.project_id
        )
    SQL

    execute <<~SQL
      DELETE FROM ci_builds
        WHERE NOT EXISTS (
          SELECT true FROM ci_stages
            WHERE ci_stages.id = ci_builds.stage_id
        )
    SQL

    add_concurrent_foreign_key :ci_stages, :projects, column: :project_id, on_delete: :cascade
    add_concurrent_foreign_key :ci_builds, :ci_stages, column: :stage_id, on_delete: :cascade
  end

  def down
    remove_foreign_key :ci_stages, column: :project_id
    remove_foreign_key :ci_builds, column: :stage_id
  end
end

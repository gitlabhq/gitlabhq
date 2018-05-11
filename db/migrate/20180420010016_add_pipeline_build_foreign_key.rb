class AddPipelineBuildForeignKey < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    execute <<~SQL
      DELETE FROM ci_builds WHERE project_id IS NULL OR commit_id IS NULL
    SQL

    execute <<~SQL
      DELETE FROM ci_builds WHERE NOT EXISTS
        (SELECT true FROM ci_pipelines WHERE ci_pipelines.id = ci_builds.commit_id)
        AND stage_id IS NULL
    SQL

    add_concurrent_foreign_key(:ci_builds, :ci_pipelines, column: :commit_id)
  end

  def down
    return unless foreign_key_exists?(:ci_builds, :ci_pipelines, column: :commit_id)

    remove_foreign_key(:ci_builds, column: :commit_id)
  end
end

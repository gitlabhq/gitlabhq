# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class OptimizeCiJobArtifacts < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # job_id is just here to be a covering index for index only scans
    # since we'll almost always be joining against ci_builds on job_id
    add_concurrent_index(:ci_job_artifacts, [:expire_at, :job_id])
    add_concurrent_index(:ci_builds, [:artifacts_expire_at], where: "artifacts_file <> ''")
  end

  def down
    remove_concurrent_index(:ci_job_artifacts, [:expire_at, :job_id])
    remove_concurrent_index(:ci_builds, [:artifacts_expire_at], where: "artifacts_file <> ''")
  end
end

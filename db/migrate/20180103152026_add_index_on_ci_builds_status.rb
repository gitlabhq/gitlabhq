# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexOnCiBuildsStatus < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  NEW_INDEX_NAME = 'index_ci_builds_project_id_and_status_for_live_jobs_partial'

  def up
    return if index_exists?(:ci_builds, [:project_id, :status], name: NEW_INDEX_NAME)

    add_concurrent_index(
      :ci_builds,
      [:project_id, :status],
      where: "status in ('running','pending', 'created')",
      name: NEW_INDEX_NAME
    )
  end

  def down
    remove_concurrent_index(:ci_builds, nil, name: NEW_INDEX_NAME)
  end
end

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PopulateMissingProjectCiCdSettings < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # Projects created after the initial migration but before the code started
    # using ProjectCiCdSetting won't have a corresponding row in
    # project_ci_cd_settings, so let's fix that.
    execute <<~SQL
      INSERT INTO project_ci_cd_settings (project_id)
      SELECT id
      FROM projects
      WHERE NOT EXISTS (
        SELECT 1
        FROM project_ci_cd_settings
        WHERE project_ci_cd_settings.project_id = projects.id
      )
    SQL
  end

  def down
    # There's nothing to revert for this migration.
  end
end

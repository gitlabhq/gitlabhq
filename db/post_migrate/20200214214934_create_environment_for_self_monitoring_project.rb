# frozen_string_literal: true

class CreateEnvironmentForSelfMonitoringProject < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute <<~SQL
      INSERT INTO environments (project_id, name, slug, created_at, updated_at)
      SELECT instance_administration_project_id, 'production', 'production', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM application_settings
      WHERE instance_administration_project_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1
        FROM environments
        INNER JOIN application_settings
        ON application_settings.instance_administration_project_id = environments.project_id
      )
    SQL
  end

  def down
    # no-op

    # This migration cannot be reversed because it cannot be ensured that the environment for the Self Monitoring Project
    # did not already exist before the migration ran - in that case, the migration does nothing, and it would be unexpected
    # behavior for that environment to be deleted by reversing this migration.
  end
end

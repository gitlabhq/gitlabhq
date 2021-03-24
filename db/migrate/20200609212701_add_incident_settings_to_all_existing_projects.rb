# frozen_string_literal: true

class AddIncidentSettingsToAllExistingProjects < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    # Add records to projects project_incident_management_settings
    # to preserve behavior for existing projects that
    # are using the create issue functionality with the default setting of true
    query = <<-SQL
      WITH project_ids AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported}(
        SELECT DISTINCT issues.project_id AS id
        FROM issues
        LEFT OUTER JOIN project_incident_management_settings
                    ON project_incident_management_settings.project_id = issues.project_id
        INNER JOIN label_links
               ON label_links.target_type = 'Issue'
                  AND label_links.target_id = issues.id
        INNER JOIN labels
               ON labels.id = label_links.label_id
        WHERE  ( project_incident_management_settings.project_id IS NULL )
               -- Use incident labels even though they could be manually added by users who
               -- are not using alert funtionality.
               AND labels.title = 'incident'
               AND labels.color = '#CC0033'
               AND labels.description = 'Denotes a disruption to IT services and the associated issues require immediate attention'
      )
      INSERT INTO project_incident_management_settings (project_id, create_issue, send_email, issue_template_key)
      SELECT project_ids.id, TRUE, FALSE, NULL
      FROM project_ids
      ON CONFLICT (project_id) DO NOTHING;
    SQL

    execute(query)
  end

  def down
    # no-op
  end
end

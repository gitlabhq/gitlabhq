class MigrateProjectFeatures < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON =
    <<-EOT
      Migrating issues_enabled, merge_requests_enabled, wiki_enabled, builds_enabled, snippets_enabled fields from projects to
      a new table called project_features.
    EOT

  def up
    sql =
      %Q{
        INSERT INTO project_features(project_id, issues_access_level, merge_requests_access_level, wiki_access_level,
        builds_access_level, snippets_access_level, created_at, updated_at)
          SELECT
          id AS project_id,
          CASE WHEN issues_enabled IS true THEN 20 ELSE 0 END AS issues_access_level,
          CASE WHEN merge_requests_enabled IS true THEN 20 ELSE 0 END AS merge_requests_access_level,
          CASE WHEN wiki_enabled IS true THEN 20 ELSE 0 END AS wiki_access_level,
          CASE WHEN builds_enabled IS true THEN 20 ELSE 0 END AS builds_access_level,
          CASE WHEN snippets_enabled IS true THEN 20 ELSE 0 END AS snippets_access_level,
          created_at,
          updated_at
          FROM projects
      }

    execute(sql)
  end

  def down
    sql = %Q{
      UPDATE projects
      SET
      issues_enabled = COALESCE((SELECT CASE WHEN issues_access_level = 20 THEN true ELSE false END AS issues_enabled FROM project_features WHERE project_features.project_id = projects.id), true),
      merge_requests_enabled = COALESCE((SELECT CASE WHEN merge_requests_access_level = 20 THEN true ELSE false END AS merge_requests_enabled FROM project_features WHERE project_features.project_id = projects.id),true),
      wiki_enabled = COALESCE((SELECT CASE WHEN wiki_access_level = 20 THEN true ELSE false END AS wiki_enabled FROM project_features WHERE project_features.project_id = projects.id), true),
      builds_enabled = COALESCE((SELECT CASE WHEN builds_access_level = 20 THEN true ELSE false END AS builds_enabled FROM project_features WHERE project_features.project_id = projects.id), true),
      snippets_enabled = COALESCE((SELECT CASE WHEN snippets_access_level = 20 THEN true ELSE false END AS snippets_enabled FROM project_features WHERE project_features.project_id = projects.id),true)
    }

    execute(sql)
  end
end

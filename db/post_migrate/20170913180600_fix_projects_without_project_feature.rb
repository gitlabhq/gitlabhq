class FixProjectsWithoutProjectFeature < ActiveRecord::Migration
  DOWNTIME = false

  def up
    # Deletes corrupted project features
    sql = "DELETE FROM project_features WHERE project_id IS NULL"
    execute(sql)

    # Creates missing project features with private visibility
    sql =
      %Q{
        INSERT INTO project_features(project_id, repository_access_level, issues_access_level, merge_requests_access_level, wiki_access_level,
        builds_access_level, snippets_access_level, created_at, updated_at)
          SELECT projects.id as project_id,
          10 as repository_access_level,
          10 as issues_access_level,
          10 as merge_requests_access_level,
          10 as wiki_access_level,
          10 as builds_access_level ,
          10 as snippets_access_level,
          projects.created_at,
          projects.updated_at
          FROM projects
          LEFT OUTER JOIN project_features ON project_features.project_id = projects.id
          WHERE (project_features.id IS NULL)
      }

    execute(sql)
  end

  def down
  end
end

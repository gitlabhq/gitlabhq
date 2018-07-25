class MigrateProjectIdForCiCommits < ActiveRecord::Migration
  def up
    subquery = 'SELECT gitlab_id FROM ci_projects WHERE ci_projects.id = ci_commits.project_id'
    execute("UPDATE ci_commits SET gl_project_id=(#{subquery}) WHERE gl_project_id IS NULL")
  end
end

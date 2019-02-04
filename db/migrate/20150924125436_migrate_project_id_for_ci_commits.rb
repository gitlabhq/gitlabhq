class MigrateProjectIdForCiCommits < ActiveRecord::Migration[4.2]
  def up
    subquery = 'SELECT gitlab_id FROM ci_projects WHERE ci_projects.id = ci_commits.project_id'
    execute("UPDATE ci_commits SET gl_project_id=(#{subquery}) WHERE gl_project_id IS NULL")
  end
end

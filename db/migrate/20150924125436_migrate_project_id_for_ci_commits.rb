class MigrateProjectIdForCiCommits < ActiveRecord::Migration
  def up
    execute(
      "UPDATE ci_commits " +
        "JOIN ci_projects ON ci_projects.id = ci_commits.project_id " +
        "SET gl_project_id=ci_projects.gitlab_id " +
        "WHERE gl_project_id IS NULL"
    )
  end
end

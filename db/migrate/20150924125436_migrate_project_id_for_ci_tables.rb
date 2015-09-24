class MigrateProjectIdForCiTables < ActiveRecord::Migration
  TABLES = %w(ci_builds ci_commits ci_events ci_runner_projects
    ci_services ci_triggers ci_variables ci_web_hooks)

  def up
    TABLES.each do |table|
      execute(
        "UPDATE #{table} " +
          "JOIN ci_projects ON ci_projects.id = #{table}.project_id " +
          "SET gl_project_id=ci_projects.gitlab_id " +
          "WHERE gl_project_id IS NULL"
      )
    end
  end
end

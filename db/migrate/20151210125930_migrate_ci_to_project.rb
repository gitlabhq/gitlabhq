class MigrateCiToProject < ActiveRecord::Migration
  def up
    migrate_project_id_for_table('ci_runner_projects')
    migrate_project_id_for_table('ci_triggers')
    migrate_project_id_for_table('ci_variables')
    migrate_project_id_for_builds

    migrate_project_column('id', 'ci_id')
    migrate_project_column('shared_runners_enabled', 'shared_runners_enabled')
    migrate_project_column('token', 'runners_token')
    migrate_project_column('coverage_regex', 'build_coverage_regex')
    migrate_project_column('allow_git_fetch', 'build_allow_git_fetch')
    migrate_project_column('timeout', 'build_timeout')
    migrate_ci_service
  end

  def down
    # We can't reverse the data
  end

  def migrate_project_id_for_table(table)
    subquery = "SELECT gitlab_id FROM ci_projects WHERE ci_projects.id = #{table}.project_id"
    execute("UPDATE #{table} SET gl_project_id=(#{subquery}) WHERE gl_project_id IS NULL")
  end

  def migrate_project_id_for_builds
    subquery = 'SELECT gl_project_id FROM ci_commits WHERE ci_commits.id = ci_builds.commit_id'
    execute("UPDATE ci_builds SET gl_project_id=(#{subquery}) WHERE gl_project_id IS NULL")
  end

  def migrate_project_column(column, new_column = nil)
    new_column ||= column
    subquery = "SELECT ci_projects.#{column} FROM ci_projects WHERE projects.id = ci_projects.gitlab_id " \
      'ORDER BY ci_projects.updated_at DESC LIMIT 1'
    execute("UPDATE projects SET #{new_column}=(#{subquery}) WHERE (#{subquery}) IS NOT NULL")
  end

  def migrate_ci_service
    subquery = "SELECT active FROM services WHERE projects.id = services.project_id AND type='GitlabCiService' LIMIT 1"
    execute("UPDATE projects SET builds_enabled=(#{subquery}) WHERE (#{subquery}) IS NOT NULL")
  end
end

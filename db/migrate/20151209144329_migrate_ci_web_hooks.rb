class MigrateCiWebHooks < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  def up
    execute(
      'INSERT INTO web_hooks (url, project_id, type, created_at, updated_at, push_events, issues_events, merge_requests_events, tag_push_events, note_events, build_events) ' \
      "SELECT ci_web_hooks.url, projects.id, 'ProjectHook', ci_web_hooks.created_at, ci_web_hooks.updated_at, " \
      "#{false_value}, #{false_value}, #{false_value}, #{false_value}, #{false_value}, #{true_value} FROM ci_web_hooks " \
      'JOIN ci_projects ON ci_web_hooks.project_id = ci_projects.id ' \
      'JOIN projects ON ci_projects.gitlab_id = projects.id'
    )
  end

  def down
  end
end

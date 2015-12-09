class MigrateCiEmails < ActiveRecord::Migration
  include Gitlab::Database

  def up
    execute(
      'INSERT INTO services (project_id, type, created_at, updated_at, active, push_events, issues_events, merge_requests_events, tag_push_events, note_events, build_events, properties) ' \
      "SELECT projects.id, 'BuildsEmailService', ci_services.created_at, ci_services.updated_at, #{true_value}, #{false_value}, #{false_value}, #{false_value}, #{false_value}, #{false_value}, #{true_value}, " \
      "CONCAT('{\"notify_only_broken_builds\":\"', ci_projects.email_only_broken_builds, " \
      "'\",\"add_pusher\":\"', ci_projects.email_add_pusher, '\",\"recipients\":\"', ci_projects.email_recipients, '\"}') " \
      'FROM ci_services ' \
      'JOIN ci_projects ON ci_services.project_id = ci_projects.id ' \
      'JOIN projects ON ci_projects.gitlab_id = projects.id ' \
      "WHERE ci_services.type = 'Ci::MailService' AND ci_services.active"
    )
  end
end

class MigrateCiEmails < ActiveRecord::Migration
  include Gitlab::Database

  def up
    # This inserts a new service: BuildsEmailService
    # It "manually" constructs the properties (JSON-encoded)
    # Migrating all ci_projects e-mail related columns
    execute(
      'INSERT INTO services (project_id, type, created_at, updated_at, active, push_events, issues_events, merge_requests_events, tag_push_events, note_events, build_events, properties) ' \
      "SELECT projects.id, 'BuildsEmailService', ci_services.created_at, ci_services.updated_at, " \
      "#{true_value}, #{false_value}, #{false_value}, #{false_value}, #{false_value}, #{false_value}, #{true_value}, " \
      "CONCAT('{\"notify_only_broken_builds\":\"', #{convert_bool('ci_projects.email_only_broken_builds')}, " \
      "'\",\"add_pusher\":\"', #{convert_bool('ci_projects.email_add_pusher')}, " \
      "'\",\"recipients\":\"', #{escape_text('ci_projects.email_recipients')}, " \
      "'\"}') " \
      'FROM ci_services ' \
      'JOIN ci_projects ON ci_services.project_id = ci_projects.id ' \
      'JOIN projects ON ci_projects.gitlab_id = projects.id ' \
      "WHERE ci_services.type = 'Ci::MailService' AND ci_services.active"
    )
  end

  def down
  end

  # This function escapes double-quotes and slash
  def escape_text(name)
    if Gitlab::Database.postgresql?
      "REPLACE(REPLACE(#{name}, '\\', '\\\\'), '\"', '\\\"')"
    else
      "REPLACE(REPLACE(#{name}, '\\\\', '\\\\\\\\'), '\\\"', '\\\\\\\"')"
    end
  end

  # This function returns 0 or 1 for column
  def convert_bool(name)
    if Gitlab::Database.postgresql?
      # PostgreSQL uses BOOLEAN type
      "CASE WHEN #{name} IS TRUE THEN '1' ELSE '0' END"
    else
      # MySQL uses TINYINT
      "#{name}"
    end
  end
end

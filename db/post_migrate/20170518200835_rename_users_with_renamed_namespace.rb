# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RenameUsersWithRenamedNamespace < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  DISALLOWED_ROOT_PATHS = %w[
    abuse_reports
    api
    autocomplete
    explore
    health_check
    import
    invites
    jwt
    koding
    member
    notification_settings
    oauth
    sent_notifications
    unicorn_test
    uploads
    users
  ]

  def up
    DISALLOWED_ROOT_PATHS.each do |path|
      update_sql = "UPDATE users SET username = namespaces.path "\
                   "FROM namespaces WHERE namespaces.owner_id = users.id "\
                   "AND namespaces.type IS NULL "\
                   "AND users.username ILIKE '#{path}'"
      connection.execute(update_sql)
    end
  end

  def down
  end
end

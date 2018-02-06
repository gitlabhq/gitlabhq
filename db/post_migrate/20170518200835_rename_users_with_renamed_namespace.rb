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
      users = Arel::Table.new(:users)
      namespaces = Arel::Table.new(:namespaces)
      predicate = namespaces[:owner_id].eq(users[:id])
                    .and(namespaces[:type].eq(nil))
                    .and(users[:username].matches(path))

      update_sql = if Gitlab::Database.postgresql?
                     "UPDATE users SET username = namespaces.path "\
                     "FROM namespaces WHERE #{predicate.to_sql}"
                   else
                     "UPDATE users INNER JOIN namespaces "\
                     "ON namespaces.owner_id = users.id "\
                     "SET username = namespaces.path "\
                     "WHERE #{predicate.to_sql}"
                   end

      connection.execute(update_sql)
    end
  end

  def down
  end
end

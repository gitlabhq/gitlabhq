# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RenameUsersWithRenamedNamespace < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  DISALLOWED_ROOT_PATHS = %w[
    -
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
    namespace_table = Arel::Table.new('namespaces')
    users_table = Arel::Table.new('users')
    matching_path = namespace_table.project(namespace_table[:path])
                      .join(users_table).on(users_table[:id].eq(namespace_table[:owner_id]))
                      .where(users_table[:username].not_eq(namespace_table[:path]))
    path_name = Arel::Nodes::SqlLiteral.new("matching_path.path FROM (#{matching_path.to_sql}) as matching_path")

    update_column_in_batches(:users, :username, path_name) do |table, query|
      query.where(table[:username].matches_any(DISALLOWED_ROOT_PATHS))
    end
  end

  def down
  end
end

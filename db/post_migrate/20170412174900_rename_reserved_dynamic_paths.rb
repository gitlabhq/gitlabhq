# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RenameReservedDynamicPaths < ActiveRecord::Migration
  include Gitlab::Database::RenameReservedPathsMigration

  DOWNTIME = false

  disable_ddl_transaction!

  DISALLOWED_ROOT_PATHS = %w[
    api
    autocomplete
    member
    explore
    uploads
    import
    notification_settings
    abuse_reports
    invites
    koding
    health_check
    jwt
    oauth
    sent_notifications
    -
  ]

  DISALLOWED_WILDCARD_PATHS = %w[objects folders file]

  def up
    rename_root_paths(DISALLOWED_ROOT_PATHS)
    rename_wildcard_paths(DISALLOWED_WILDCARD_PATHS)
  end

  def down
    # nothing to do
  end
end

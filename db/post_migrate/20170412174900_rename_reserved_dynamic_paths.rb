# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RenameReservedDynamicPaths < ActiveRecord::Migration
  include Gitlab::Database::RenameReservedPathsMigration::V1

  DOWNTIME = false

  disable_ddl_transaction!

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
    uploads
    users
  ]

  DISALLOWED_WILDCARD_PATHS = %w[
    environments/folders
    gitlab-lfs/objects
    info/lfs/objects
  ]

  def up
    rename_root_paths(DISALLOWED_ROOT_PATHS)
    rename_wildcard_paths(DISALLOWED_WILDCARD_PATHS)
  end

  def down
    # nothing to do
  end
end

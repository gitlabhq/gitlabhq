# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RenameAllReservedPathsAgain < ActiveRecord::Migration
  include Gitlab::Database::RenameReservedPathsMigration::V1

  DOWNTIME = false

  disable_ddl_transaction!

  TOP_LEVEL_ROUTES = %w[
      -
      .well-known
      abuse_reports
      admin
      api
      assets
      autocomplete
      ci
      dashboard
      explore
      files
      groups
      health_check
      help
      import
      invites
      jwt
      koding
      notification_settings
      oauth
      profile
      projects
      public
      robots.txt
      s
      search
      sent_notifications
      snippets
      u
      unicorn_test
      unsubscribes
      uploads
      users
  ].freeze

  PROJECT_WILDCARD_ROUTES = %w[
      badges
      blame
      blob
      builds
      commits
      create
      create_dir
      edit
      environments/folders
      files
      find_file
      gitlab-lfs/objects
      info/lfs/objects
      new
      preview
      raw
      refs
      tree
      update
      wikis
    ].freeze

  GROUP_ROUTES = %w[
      activity
      analytics
      audit_events
      avatar
      edit
      group_members
      hooks
      issues
      labels
      ldap
      ldap_group_links
      merge_requests
      milestones
      notification_setting
      pipeline_quota
      projects
  ].freeze

  def up
    disable_statement_timeout

    TOP_LEVEL_ROUTES.each { |route| rename_root_paths(route) }
    PROJECT_WILDCARD_ROUTES.each { |route| rename_wildcard_paths(route) }
    GROUP_ROUTES.each { |route| rename_child_paths(route) }
  end

  def down
    disable_statement_timeout

    revert_renames
  end
end

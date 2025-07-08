# frozen_string_literal: true

class RemoveMetricsUsersStarredDashboards < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  # no-op due to gitlab.com deploy incident
  # https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/26996
  # See db/post_migrate/20250701220912_drop_user_starred_dashboards_again.rb for replacement
  def up; end

  def down; end
end

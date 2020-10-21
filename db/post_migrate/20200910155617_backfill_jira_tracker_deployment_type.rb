# frozen_string_literal: true

class BackfillJiraTrackerDeploymentType < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    # no-op
    # this migration was reverted
    # in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/45205
    # due to https://gitlab.com/gitlab-com/gl-infra/production/-/issues/2820
  end

  def down
    # no-op
    # intentionally blank
  end
end

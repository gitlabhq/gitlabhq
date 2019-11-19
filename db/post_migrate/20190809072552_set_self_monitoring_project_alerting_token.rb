# frozen_string_literal: true

class SetSelfMonitoringProjectAlertingToken < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    # no-op
    # Converted to no-op in https://gitlab.com/gitlab-org/gitlab/merge_requests/17049.

    # This migration has been made a no-op because the pre-requisite migration
    # which creates the self-monitoring project has already been removed in
    # https://gitlab.com/gitlab-org/gitlab/merge_requests/16864. As
    # such, this migration would do nothing.
  end

  def down
    # no-op
  end
end

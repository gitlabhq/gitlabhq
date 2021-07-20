# frozen_string_literal: true

class ScheduleLatestPipelineIdPopulation < ActiveRecord::Migration[6.1]
  def up
    # no-op: This migration has been marked as no-op and replaced by
    # `ReScheduleLatestPipelineIdPopulation` as we've found some problems.
    # For more information: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/65280
  end

  def down
    # no-op
  end
end

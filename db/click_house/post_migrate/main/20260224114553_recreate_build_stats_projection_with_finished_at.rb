# frozen_string_literal: true

# No-op: This migration is replaced by a later migration that first fixes the broken
# by_project_pipeline_finished_at_name projection (which used SELECT * and was materialized
# before new columns were added), then recreates this projection.
# See: https://gitlab.com/gitlab-org/gitlab/-/work_items/591727
class RecreateBuildStatsProjectionWithFinishedAt < ClickHouse::Migration
  def up
    # no-op
  end

  def down
    # no-op
  end
end

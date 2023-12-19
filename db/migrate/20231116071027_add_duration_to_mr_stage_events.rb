# frozen_string_literal: true

class AddDurationToMrStageEvents < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  def change
    add_column :analytics_cycle_analytics_merge_request_stage_events, :duration_in_milliseconds, :bigint
  end
end

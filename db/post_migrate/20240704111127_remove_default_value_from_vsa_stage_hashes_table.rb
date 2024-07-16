# frozen_string_literal: true

class RemoveDefaultValueFromVsaStageHashesTable < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def up
    change_column_default :analytics_cycle_analytics_stage_event_hashes, :organization_id, nil
  end

  def down
    change_column_default :analytics_cycle_analytics_stage_event_hashes, :organization_id, 1
  end
end

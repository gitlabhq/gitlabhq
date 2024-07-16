# frozen_string_literal: true

class AddOrganizationIdColumnToStageEventHashes < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :analytics_cycle_analytics_stage_event_hashes, :organization_id, :bigint, null: false, default: 1
  end
end

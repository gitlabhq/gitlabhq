# frozen_string_literal: true

class AddRsourceMilestoneEventsShardingKey < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :resource_milestone_events, :namespace_id, :bigint, null: false, default: 0
  end
end

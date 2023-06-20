# frozen_string_literal: true

class AddNamespaceAggregationScheduleLeaseDurationToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings,
      :namespace_aggregation_schedule_lease_duration_in_seconds,
      :integer,
      default: 5.minutes,
      null: false
  end
end

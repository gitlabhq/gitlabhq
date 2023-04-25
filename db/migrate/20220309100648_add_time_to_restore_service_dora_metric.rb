# frozen_string_literal: true

class AddTimeToRestoreServiceDoraMetric < Gitlab::Database::Migration[1.0]
  def change
    add_column :dora_daily_metrics, :time_to_restore_service_in_seconds, :integer
  end
end

# frozen_string_literal: true

class AddProjectIdToDoraDailyMetrics < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :dora_daily_metrics, :project_id, :bigint
  end
end

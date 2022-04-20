# frozen_string_literal: true

class AddDoraIncidentsCount < Gitlab::Database::Migration[1.0]
  def change
    add_column :dora_daily_metrics, :incidents_count, :integer
  end
end

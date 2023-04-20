# frozen_string_literal: true

class CreateDoraPerformanceScores < Gitlab::Database::Migration[2.1]
  def change
    create_table :dora_performance_scores do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.date :date, null: false
      t.integer :deployment_frequency, limit: 2
      t.integer :lead_time_for_changes, limit: 2
      t.integer :time_to_restore_service, limit: 2
      t.integer :change_failure_rate, limit: 2

      t.index [:project_id, :date], unique: true
    end
  end
end

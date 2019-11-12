# frozen_string_literal: true

class CreatePlanLimits < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :plan_limits, id: false do |t|
      t.references :plan, foreign_key: { on_delete: :cascade }, null: false, index: { unique: true }
      t.integer :ci_active_pipelines, null: false, default: 0
      t.integer :ci_pipeline_size, null: false, default: 0
      t.integer :ci_active_jobs, null: false, default: 0
    end
  end
end

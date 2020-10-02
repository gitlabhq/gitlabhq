# frozen_string_literal: true

class AddApiFuzzingToPlanLimits < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :plan_limits, "ci_max_artifact_size_api_fuzzing", :integer, default: 0, null: false
  end
end

# frozen_string_literal: true

class AddMaxPipelinesPerMergeTrainToPlanLimits < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def change
    add_column :plan_limits, :max_pipelines_per_merge_train, :smallint, default: 20, null: false
  end
end

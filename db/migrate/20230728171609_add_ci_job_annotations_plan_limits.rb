# frozen_string_literal: true

class AddCiJobAnnotationsPlanLimits < Gitlab::Database::Migration[2.1]
  def change
    add_column :plan_limits, :ci_max_artifact_size_annotations, :integer, null: false, default: 0
    add_column :plan_limits, :ci_job_annotations_size, :integer, null: false, default: 81920
    add_column :plan_limits, :ci_job_annotations_num, :integer, null: false, default: 20
  end
end

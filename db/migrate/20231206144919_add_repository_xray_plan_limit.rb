# frozen_string_literal: true

class AddRepositoryXrayPlanLimit < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '16.7'

  def change
    add_column :plan_limits, :ci_max_artifact_size_repository_xray, :bigint, default: 1.gigabyte, null: false
  end
end

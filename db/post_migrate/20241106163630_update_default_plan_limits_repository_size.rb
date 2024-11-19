# frozen_string_literal: true

class UpdateDefaultPlanLimitsRepositorySize < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    change_column_default :plan_limits, :repository_size, from: 0, to: nil
  end
end

# frozen_string_literal: true

class AllowNullForPlanLimitsRepositorySize < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    change_column_null :plan_limits, :repository_size, true
  end
end

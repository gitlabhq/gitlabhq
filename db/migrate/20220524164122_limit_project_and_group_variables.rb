# frozen_string_literal: true

class LimitProjectAndGroupVariables < Gitlab::Database::Migration[2.0]
  def change
    add_column(:plan_limits, :project_ci_variables, :integer, default: 200, null: false)
    add_column(:plan_limits, :group_ci_variables, :integer, default: 200, null: false)
  end
end

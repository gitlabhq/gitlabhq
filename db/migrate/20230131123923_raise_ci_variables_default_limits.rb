# frozen_string_literal: true

class RaiseCiVariablesDefaultLimits < Gitlab::Database::Migration[2.1]
  def change
    change_column_default(:plan_limits, :project_ci_variables, from: 200, to: 8000)
    change_column_default(:plan_limits, :group_ci_variables, from: 200, to: 30000)
  end
end

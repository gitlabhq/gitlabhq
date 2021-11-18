# frozen_string_literal: true

class CreateDotenvApplicationLimits < Gitlab::Database::Migration[1.0]
  def change
    add_column(:plan_limits, :dotenv_variables, :integer, default: 20, null: false)
    add_column(:plan_limits, :dotenv_size, :integer, default: 5.kilobytes, null: false)
  end
end

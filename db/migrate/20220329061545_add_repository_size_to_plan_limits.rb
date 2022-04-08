# frozen_string_literal: true

class AddRepositorySizeToPlanLimits < Gitlab::Database::Migration[1.0]
  def up
    add_column(:plan_limits, :repository_size, :bigint, default: 0, null: false)
  end

  def down
    remove_column(:plan_limits, :repository_size)
  end
end

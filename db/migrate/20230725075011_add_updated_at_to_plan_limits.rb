# frozen_string_literal: true

class AddUpdatedAtToPlanLimits < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :plan_limits, :updated_at, :datetime_with_timezone, null: false, default: -> { 'NOW()' }
  end
end

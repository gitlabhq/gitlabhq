# frozen_string_literal: true

class AddMlModelMaxFileSizeToPlanLimits < Gitlab::Database::Migration[2.1]
  def change
    add_column(:plan_limits, :ml_model_max_file_size, :bigint, default: 10.gigabytes, null: false)
  end
end

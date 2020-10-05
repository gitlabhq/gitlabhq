# frozen_string_literal: true

class AddGolangPackageMaxFileSizeToPlanLimits < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column(:plan_limits, :golang_max_file_size, :bigint, default: 100.megabytes, null: false)
  end
end

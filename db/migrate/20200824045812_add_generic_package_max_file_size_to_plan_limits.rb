# frozen_string_literal: true

class AddGenericPackageMaxFileSizeToPlanLimits < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column(:plan_limits, :generic_packages_max_file_size, :bigint, default: 5.gigabytes, null: false)
  end
end

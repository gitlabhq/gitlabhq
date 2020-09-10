# frozen_string_literal: true

class UpdatePackageFileSizePlanLimitsDefaults < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    change_column_default(:plan_limits, :maven_max_file_size, from: 50.megabytes, to: 3.gigabytes)
    change_column_default(:plan_limits, :conan_max_file_size, from: 50.megabytes, to: 3.gigabytes)
    change_column_default(:plan_limits, :nuget_max_file_size, from: 50.megabytes, to: 500.megabytes)
    change_column_default(:plan_limits, :npm_max_file_size,   from: 50.megabytes, to: 500.megabytes)
    change_column_default(:plan_limits, :pypi_max_file_size,  from: 50.megabytes, to: 3.gigabytes)
  end
end

# frozen_string_literal: true

class AddPackageMaxFileSizeToPlanLimits < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column(:plan_limits, :conan_max_file_size, :bigint, default: 50.megabytes, null: false)
    add_column(:plan_limits, :maven_max_file_size, :bigint, default: 50.megabytes, null: false)
    add_column(:plan_limits, :npm_max_file_size, :bigint, default: 50.megabytes, null: false)
    add_column(:plan_limits, :nuget_max_file_size, :bigint, default: 50.megabytes, null: false)
    add_column(:plan_limits, :pypi_max_file_size, :bigint, default: 50.megabytes, null: false)
  end
end

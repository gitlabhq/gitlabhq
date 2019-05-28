# frozen_string_literal: true

class AddPackagesSizeToProjectStatistics < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :project_statistics, :packages_size, :bigint
  end
end

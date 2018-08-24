# frozen_string_literal: true
class AddPackagesEnabledToProject < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :projects, :packages_enabled, :boolean
  end
end

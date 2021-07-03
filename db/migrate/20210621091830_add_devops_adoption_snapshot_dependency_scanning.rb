# frozen_string_literal: true

class AddDevopsAdoptionSnapshotDependencyScanning < ActiveRecord::Migration[6.1]
  def change
    add_column :analytics_devops_adoption_snapshots, :dependency_scanning_enabled_count, :integer
  end
end

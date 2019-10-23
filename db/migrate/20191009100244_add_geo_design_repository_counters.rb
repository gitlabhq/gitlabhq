# frozen_string_literal: true

class AddGeoDesignRepositoryCounters < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    change_table :geo_node_statuses do |t|
      t.column :design_repositories_count, :integer
      t.column :design_repositories_synced_count, :integer
      t.column :design_repositories_failed_count, :integer
      t.column :design_repositories_registry_count, :integer
    end
  end
end

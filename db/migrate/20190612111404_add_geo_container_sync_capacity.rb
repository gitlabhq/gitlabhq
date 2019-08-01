# frozen_string_literal: true

class AddGeoContainerSyncCapacity < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    change_table :geo_nodes do |t|
      t.column :container_repositories_max_capacity, :integer, default: 10, null: false
    end
  end
end

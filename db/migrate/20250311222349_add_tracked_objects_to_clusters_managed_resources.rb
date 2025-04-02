# frozen_string_literal: true

class AddTrackedObjectsToClustersManagedResources < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :clusters_managed_resources, :tracked_objects, :jsonb, null: false, default: []
  end
end

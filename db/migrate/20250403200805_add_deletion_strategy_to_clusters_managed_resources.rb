# frozen_string_literal: true

class AddDeletionStrategyToClustersManagedResources < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :clusters_managed_resources, :deletion_strategy, :integer, limit: 2, null: false, default: 0
  end
end

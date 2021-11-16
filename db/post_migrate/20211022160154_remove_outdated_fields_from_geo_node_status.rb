# frozen_string_literal: true

class RemoveOutdatedFieldsFromGeoNodeStatus < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    remove_column :geo_node_statuses, :attachments_count, :integer
    remove_column :geo_node_statuses, :attachments_synced_count, :integer
    remove_column :geo_node_statuses, :attachments_failed_count, :integer
    remove_column :geo_node_statuses, :attachments_synced_missing_on_primary_count, :integer
  end
end

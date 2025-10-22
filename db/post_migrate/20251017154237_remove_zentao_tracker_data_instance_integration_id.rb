# frozen_string_literal: true

class RemoveZentaoTrackerDataInstanceIntegrationId < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def up
    remove_column :zentao_tracker_data, :instance_integration_id
  end

  def down
    add_column :zentao_tracker_data, :instance_integration_id, :bigint
  end
end

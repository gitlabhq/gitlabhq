# frozen_string_literal: true

class AddInstanceIntegrationFkToZentaoTrackerData < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :zentao_tracker_data, :instance_integrations,
      column: :instance_integration_id,
      on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :zentao_tracker_data, column: :instance_integration_id
  end
end

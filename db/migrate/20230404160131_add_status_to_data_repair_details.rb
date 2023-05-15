# frozen_string_literal: true

class AddStatusToDataRepairDetails < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_container_registry_data_repair_details_on_status'

  def up
    unless column_exists?(:container_registry_data_repair_details, :status)
      add_column(:container_registry_data_repair_details, :status, :integer, default: 0, null: false, limit: 2)
    end

    add_concurrent_index :container_registry_data_repair_details, :status, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :container_registry_data_repair_details, name: INDEX_NAME
    remove_column :container_registry_data_repair_details, :status
  end
end

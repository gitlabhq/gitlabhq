# frozen_string_literal: true

class CreateContainerRegistryDataRepairDetails < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    create_table :container_registry_data_repair_details, id: false do |t|
      t.integer :missing_count, default: 0
      t.references :project,
        primary_key: true,
        default: nil,
        index: false,
        foreign_key: { to_table: :projects, on_delete: :cascade }
      t.timestamps_with_timezone null: false
    end
  end
end

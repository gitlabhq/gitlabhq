# frozen_string_literal: true

class CreateAscpComponents < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  disable_ddl_transaction!

  def up
    create_table :ascp_components do |t|
      # 8-byte columns first (timestamps, bigints)
      t.timestamps_with_timezone null: false
      t.bigint :project_id, null: false
      t.bigint :scan_id, null: false

      # Variable-size columns at the end
      t.text :title, limit: 255, null: false
      t.text :sub_directory, limit: 1024, null: false
      t.text :description, limit: 4096
      t.text :expected_user_behavior, limit: 4096
    end

    # Indexes (no standalone project_id - composite indexes cover it)
    add_index :ascp_components, [:project_id, :scan_id, :sub_directory],
      unique: true, name: 'idx_ascp_components_on_project_scan_subdir'
    add_index :ascp_components, :scan_id

    add_concurrent_foreign_key :ascp_components, :ascp_scans,
      column: :scan_id, on_delete: :cascade
  end

  def down
    drop_table :ascp_components
  end
end

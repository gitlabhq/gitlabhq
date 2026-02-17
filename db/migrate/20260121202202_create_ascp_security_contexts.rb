# frozen_string_literal: true

class CreateAscpSecurityContexts < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  disable_ddl_transaction!

  def up
    create_table :ascp_security_contexts do |t|
      # 8-byte columns first (timestamps, bigints)
      t.timestamps_with_timezone null: false
      t.bigint :project_id, null: false
      t.bigint :component_id, null: false
      t.bigint :scan_id, null: false

      # Variable-size columns at the end
      t.text :summary, limit: 4096
      t.text :authentication_model, limit: 1024
      t.text :authorization_model, limit: 1024
      t.text :data_sensitivity, limit: 255
    end

    # Indexes (no standalone project_id - composite indexes cover it)
    add_index :ascp_security_contexts, [:project_id, :scan_id, :component_id],
      unique: true, name: 'idx_ascp_security_contexts_on_project_scan_comp'
    add_index :ascp_security_contexts, :component_id
    add_index :ascp_security_contexts, :scan_id

    add_concurrent_foreign_key :ascp_security_contexts, :ascp_components,
      column: :component_id, on_delete: :cascade
    add_concurrent_foreign_key :ascp_security_contexts, :ascp_scans,
      column: :scan_id, on_delete: :cascade
  end

  def down
    drop_table :ascp_security_contexts
  end
end

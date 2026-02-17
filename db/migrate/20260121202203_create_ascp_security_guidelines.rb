# frozen_string_literal: true

class CreateAscpSecurityGuidelines < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  disable_ddl_transaction!

  def up
    create_table :ascp_security_guidelines do |t|
      # 8-byte columns first (timestamps, bigints)
      t.timestamps_with_timezone null: false
      t.bigint :project_id, null: false
      t.bigint :security_context_id, null: false
      t.bigint :scan_id, null: false

      # 2-byte columns (smallint via limit: 2)
      t.integer :severity_if_violated, limit: 2, default: 0, null: false

      # Variable-size columns at the end
      t.text :name, limit: 255, null: false
      t.text :operation, limit: 1024, null: false
      t.text :legitimate_use, limit: 4096
      t.text :security_boundary, limit: 4096
      t.text :business_context, limit: 4096
    end

    # Indexes (no standalone project_id - composite indexes cover it)
    add_index :ascp_security_guidelines, [:project_id, :security_context_id],
      name: 'idx_ascp_security_guidelines_on_proj_ctx'
    add_index :ascp_security_guidelines, :scan_id
    add_index :ascp_security_guidelines, :security_context_id

    add_concurrent_foreign_key :ascp_security_guidelines, :ascp_security_contexts,
      column: :security_context_id, on_delete: :cascade
    add_concurrent_foreign_key :ascp_security_guidelines, :ascp_scans,
      column: :scan_id, on_delete: :cascade
  end

  def down
    drop_table :ascp_security_guidelines
  end
end

# frozen_string_literal: true

class CreateAscpScans < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  disable_ddl_transaction!

  def up
    create_table :ascp_scans do |t|
      # 8-byte columns first (timestamps, bigints)
      t.timestamps_with_timezone null: false
      t.bigint :project_id, null: false
      t.bigint :base_scan_id

      # 4-byte columns
      t.integer :scan_sequence, null: false

      # 2-byte columns (smallint via limit: 2)
      t.integer :scan_type, limit: 2, null: false, default: 0

      # Variable-size columns at the end
      t.text :commit_sha, limit: 64, null: false
      t.text :base_commit_sha, limit: 64
    end

    # Add indexes (no standalone project_id index - composite index covers it)
    add_index :ascp_scans, [:project_id, :scan_sequence], unique: true
    add_index :ascp_scans, :commit_sha
    add_index :ascp_scans, :base_scan_id
    add_index :ascp_scans, [:project_id, :scan_type]

    # Add foreign key for self-referential base_scan_id (optional - incremental scans only)
    # Note: project_id uses loose FK (configured in config/gitlab_loose_foreign_keys.yml)
    # to avoid blocking deletes on large projects
    add_concurrent_foreign_key :ascp_scans, :ascp_scans, column: :base_scan_id, on_delete: :nullify
  end

  def down
    drop_table :ascp_scans
  end
end

# frozen_string_literal: true

class AddSbomScanResults < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'

  def up
    create_table :sbom_vulnerability_scan_results do |t| # rubocop:disable Migration/EnsureFactoryForTable -- Factory exists but matches naming structure of SbomScan model
      t.timestamps_with_timezone null: false
      t.bigint :project_id, null: false
      t.integer :result_file_store, default: 1, limit: 2
      t.text :result_file, limit: 255
    end
  end

  def down
    drop_table :sbom_vulnerability_scan_results, if_exists: true
  end
end

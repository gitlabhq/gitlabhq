# frozen_string_literal: true

class LinkSbomScansWithResults < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  disable_ddl_transaction!

  TABLE_NAME = :sbom_vulnerability_scans

  def up
    with_lock_retries do
      add_column TABLE_NAME, :sbom_vulnerability_scan_result_id, :bigint
      add_column TABLE_NAME, :sbom_digest, :text
    end
    add_text_limit TABLE_NAME, :sbom_digest, 1024

    add_concurrent_foreign_key TABLE_NAME, :sbom_vulnerability_scan_results,
      column: :sbom_vulnerability_scan_result_id,
      foreign_key: true,
      validate: false

    add_concurrent_index TABLE_NAME, [:sbom_vulnerability_scan_result_id],
      name: 'index_sbom_vulnerability_scans_on_sbom_scan_result_id'

    add_concurrent_index TABLE_NAME, [:project_id, :sbom_digest],
      name: 'index_sbom_vulnerability_scans_on_project_id_and_sbom_digest'

    remove_concurrent_index_by_name TABLE_NAME, name: 'index_sbom_vulnerability_scans_on_project_id'
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME,
      name: 'index_sbom_vulnerability_scans_on_sbom_scan_result_id'
    remove_concurrent_index_by_name TABLE_NAME,
      name: 'index_sbom_vulnerability_scans_on_project_id_and_sbom_digest'
    add_concurrent_index TABLE_NAME, [:project_id],
      name: 'index_sbom_vulnerability_scans_on_project_id'

    with_lock_retries do
      remove_column TABLE_NAME, :sbom_digest, if_exists: true
      remove_column TABLE_NAME, :sbom_vulnerability_scan_result_id, if_exists: true
    end
  end
end

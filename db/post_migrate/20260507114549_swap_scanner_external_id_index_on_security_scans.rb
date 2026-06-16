# frozen_string_literal: true

class SwapScannerExternalIdIndexOnSecurityScans < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  OLD_UNIQUE_INDEX = 'idx_security_scans_on_build_and_scan_type'
  NEW_UNIQUE_INDEX = 'idx_security_scans_on_build_scan_type_and_scanner'

  disable_ddl_transaction!

  def up
    unless index_exists_by_name?(:security_scans, NEW_UNIQUE_INDEX)
      # rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/621
      add_concurrent_index(
        :security_scans,
        [:build_id, :scan_type, :scanner_external_id],
        unique: true,
        nulls_not_distinct: true,
        name: NEW_UNIQUE_INDEX
      )
      # rubocop:enable Migration/PreventIndexCreation
    end

    remove_concurrent_index_by_name :security_scans, OLD_UNIQUE_INDEX
  end

  def down
    unless index_exists_by_name?(:security_scans, OLD_UNIQUE_INDEX)
      add_concurrent_index(
        :security_scans,
        [:build_id, :scan_type],
        unique: true,
        name: OLD_UNIQUE_INDEX
      )
    end

    remove_concurrent_index_by_name :security_scans, NEW_UNIQUE_INDEX
  end
end

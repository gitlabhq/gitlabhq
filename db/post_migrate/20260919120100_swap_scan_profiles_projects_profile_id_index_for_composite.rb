# frozen_string_literal: true

class SwapScanProfilesProjectsProfileIdIndexForComposite < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.5'

  TABLE_NAME = :security_scan_profiles_projects
  OLD_INDEX_NAME = 'idx_security_scan_profiles_projects_on_security_scan_profile_id'
  NEW_INDEX_NAME = 'idx_scan_profiles_projects_on_profile_id_and_archived'

  # Replace the single-column index on security_scan_profile_id with a composite
  # (security_scan_profile_id, archived) index. The composite still backs the FK
  # cascade delete (which filters on the leading column) and additionally serves
  # the archived-aware count queries, so no separate index is needed.
  def up
    add_concurrent_index TABLE_NAME, [:security_scan_profile_id, :archived], name: NEW_INDEX_NAME
    remove_concurrent_index_by_name TABLE_NAME, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :security_scan_profile_id, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name TABLE_NAME, NEW_INDEX_NAME
  end
end

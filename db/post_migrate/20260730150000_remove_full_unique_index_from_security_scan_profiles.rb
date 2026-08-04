# frozen_string_literal: true

class RemoveFullUniqueIndexFromSecurityScanProfiles < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.3'

  # Post-deployment so the old full unique index survives until the new code (which upserts against
  # index_security_scan_profiles_unique_name_not_deleted) is fully deployed. Dropping it in the
  # regular migration would break profile creation on instances still running old code during the
  # rollout window.

  TABLE = :security_scan_profiles
  OLD_UNIQUE_INDEX = 'index_security_scan_profiles_namespace_scan_type_name'
  UNIQUE_COLUMNS = 'namespace_id, scan_type, LOWER(name)'

  def up
    remove_concurrent_index_by_name TABLE, OLD_UNIQUE_INDEX
  end

  def down
    # Recreating the full unique index will fail if soft-deleted rows already share a name.
    add_concurrent_index TABLE, UNIQUE_COLUMNS, unique: true, name: OLD_UNIQUE_INDEX
  end
end

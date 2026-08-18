# frozen_string_literal: true

class ScopeSecurityScanProfileNameUniquenessToNotDeleted < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.3'

  # Adds a partial unique index on (namespace_id, scan_type, lower(name)) scoped to
  # WHERE deleted_at IS NULL so a soft-deleted name can be reused, plus a plain namespace_id
  # index to preserve the FK/loose-FK coverage the old full unique index provided (it led with
  # namespace_id). The old full unique index is dropped separately in a post-deployment migration
  # so it survives until the new code (which targets the new index) is fully deployed.

  TABLE = :security_scan_profiles

  FK_INDEX = 'index_security_scan_profiles_on_namespace_id'
  NEW_UNIQUE_INDEX = 'index_security_scan_profiles_unique_name_not_deleted'

  UNIQUE_COLUMNS = 'namespace_id, scan_type, LOWER(name)'

  def up
    add_concurrent_index TABLE, :namespace_id, name: FK_INDEX
    add_concurrent_index TABLE, UNIQUE_COLUMNS, unique: true, where: 'deleted_at IS NULL', name: NEW_UNIQUE_INDEX
  end

  def down
    remove_concurrent_index_by_name TABLE, NEW_UNIQUE_INDEX
    remove_concurrent_index_by_name TABLE, FK_INDEX
  end
end

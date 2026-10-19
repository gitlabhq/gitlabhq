# frozen_string_literal: true

class WidenImportSyncExternalObjectsKindConstraint < Gitlab::Database::Migration[2.3]
  milestone '19.6'
  disable_ddl_transaction!

  TABLE_NAME = :import_sync_external_objects
  KIND_CONSTRAINT = 'chk_import_sync_external_objects_kind'
  OLD_KIND_CHECK = 'kind BETWEEN 0 AND 2'
  NEW_KIND_CHECK = 'kind BETWEEN 0 AND 4'

  def up
    remove_check_constraint TABLE_NAME, KIND_CONSTRAINT
    add_check_constraint TABLE_NAME, NEW_KIND_CHECK, KIND_CONSTRAINT
  end

  def down
    remove_check_constraint TABLE_NAME, KIND_CONSTRAINT
    add_check_constraint TABLE_NAME, OLD_KIND_CHECK, KIND_CONSTRAINT
  end
end

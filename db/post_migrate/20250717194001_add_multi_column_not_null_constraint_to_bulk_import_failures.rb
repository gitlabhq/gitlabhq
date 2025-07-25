# frozen_string_literal: true

class AddMultiColumnNotNullConstraintToBulkImportFailures < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint(:bulk_import_failures, :project_id,
      :namespace_id, :organization_id)
  end

  def down
    remove_multi_column_not_null_constraint(:bulk_import_failures, :project_id,
      :namespace_id, :organization_id)
  end
end

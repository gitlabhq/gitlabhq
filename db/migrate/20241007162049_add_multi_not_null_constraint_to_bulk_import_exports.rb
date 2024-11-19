# frozen_string_literal: true

class AddMultiNotNullConstraintToBulkImportExports < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint(:bulk_import_exports, :group_id, :project_id)
  end

  def down
    remove_multi_column_not_null_constraint(:bulk_import_exports, :group_id, :project_id)
  end
end

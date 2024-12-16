# frozen_string_literal: true

class AddMultiNotNullConstraintToBulkImportEntities < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint(:bulk_import_entities, :namespace_id, :project_id, :organization_id)
  end

  def down
    remove_multi_column_not_null_constraint(:bulk_import_entities, :namespace_id, :project_id, :organization_id)
  end
end

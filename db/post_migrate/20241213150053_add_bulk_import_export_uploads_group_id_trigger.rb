# frozen_string_literal: true

class AddBulkImportExportUploadsGroupIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  def up
    install_sharding_key_assignment_trigger(
      table: :bulk_import_export_uploads,
      sharding_key: :group_id,
      parent_table: :bulk_import_exports,
      parent_sharding_key: :group_id,
      foreign_key: :export_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :bulk_import_export_uploads,
      sharding_key: :group_id,
      parent_table: :bulk_import_exports,
      parent_sharding_key: :group_id,
      foreign_key: :export_id
    )
  end
end

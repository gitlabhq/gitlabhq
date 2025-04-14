# frozen_string_literal: true

class AddBulkImportConfigurationsOrganizationIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def up
    install_sharding_key_assignment_trigger(
      table: :bulk_import_configurations,
      sharding_key: :organization_id,
      parent_table: :bulk_imports,
      parent_sharding_key: :organization_id,
      foreign_key: :bulk_import_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :bulk_import_configurations,
      sharding_key: :organization_id,
      parent_table: :bulk_imports,
      parent_sharding_key: :organization_id,
      foreign_key: :bulk_import_id
    )
  end
end

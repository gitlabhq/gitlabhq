# frozen_string_literal: true

class AddOrganizationIdToBulkImportExports < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  TABLE_NAME = 'bulk_import_exports'

  def change
    add_column TABLE_NAME, :organization_id, :bigint, if_not_exists: true
  end
end

# frozen_string_literal: true

class AddOrganizationIdToBulkImportFailures < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :bulk_import_failures, :organization_id, :bigint
  end
end

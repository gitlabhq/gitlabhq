# frozen_string_literal: true

class AddOrganizationIdToBulkImportConfigurations < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :bulk_import_configurations, :organization_id, :bigint
  end
end

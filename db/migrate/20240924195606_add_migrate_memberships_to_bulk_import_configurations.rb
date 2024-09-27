# frozen_string_literal: true

class AddMigrateMembershipsToBulkImportConfigurations < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :bulk_import_configurations, :migrate_memberships, :boolean, default: true, null: false
  end
end

# frozen_string_literal: true

class AddMigrateProjectsToBulkImportEntities < Gitlab::Database::Migration[2.1]
  def change
    add_column :bulk_import_entities, :migrate_projects, :boolean, null: false, default: true
  end
end

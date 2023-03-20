# frozen_string_literal: true

class AddHasFailuresColumnToBulkImportEntities < Gitlab::Database::Migration[2.1]
  def change
    add_column :bulk_import_entities, :has_failures, :boolean, default: false
  end
end

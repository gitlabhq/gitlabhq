# frozen_string_literal: true

class AddSourceIdToBulkImportEntities < Gitlab::Database::Migration[2.0]
  def change
    add_column :bulk_import_entities, :source_xid, :integer
  end
end

# frozen_string_literal: true

class AddEnterpriseBooleanToBulkImports < Gitlab::Database::Migration[2.0]
  def change
    add_column :bulk_imports, :source_enterprise, :boolean, default: true, null: false
  end
end

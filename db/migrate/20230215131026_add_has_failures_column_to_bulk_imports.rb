# frozen_string_literal: true

class AddHasFailuresColumnToBulkImports < Gitlab::Database::Migration[2.1]
  def change
    add_column :bulk_imports, :has_failures, :boolean, default: false
  end
end

# frozen_string_literal: true

class AddSourceVersionToBulkImports < Gitlab::Database::Migration[1.0]
  def change
    add_column :bulk_imports, :source_version, :text # rubocop:disable Migration/AddLimitToTextColumns
  end
end

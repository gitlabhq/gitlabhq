# frozen_string_literal: true

class AddFieldsToBulkImportFailures < Gitlab::Database::Migration[2.2]
  milestone '16.6'

  # rubocop:disable Migration/AddLimitToTextColumns
  def change
    add_column :bulk_import_failures, :source_url, :text
    add_column :bulk_import_failures, :source_title, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end

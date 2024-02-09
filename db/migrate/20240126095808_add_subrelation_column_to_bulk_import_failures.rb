# frozen_string_literal: true

class AddSubrelationColumnToBulkImportFailures < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  # rubocop:disable Migration/AddLimitToTextColumns -- added in a separate migration
  def change
    add_column :bulk_import_failures, :subrelation, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end

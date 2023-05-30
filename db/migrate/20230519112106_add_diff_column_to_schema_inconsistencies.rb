# frozen_string_literal: true

class AddDiffColumnToSchemaInconsistencies < Gitlab::Database::Migration[2.1]
  # rubocop:disable Migration/AddLimitToTextColumns
  # rubocop:disable Rails/NotNullColumn
  # limit is added in 20230519135414
  def change
    add_column :schema_inconsistencies, :diff, :text, null: false
  end
  # rubocop:enable Migration/AddLimitToTextColumns
  # rubocop:enable Rails/NotNullColumn
end

# frozen_string_literal: true

class AddUuidColumnToSbomOccurrences < Gitlab::Database::Migration[2.1]
  def change
    add_column :sbom_occurrences, :uuid, :uuid, null: false # rubocop:disable Rails/NotNullColumn
  end
end

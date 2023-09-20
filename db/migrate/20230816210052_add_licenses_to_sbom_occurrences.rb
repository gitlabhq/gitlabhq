# frozen_string_literal: true

class AddLicensesToSbomOccurrences < Gitlab::Database::Migration[2.1]
  def change
    add_column :sbom_occurrences, :licenses, :jsonb, default: []
  end
end

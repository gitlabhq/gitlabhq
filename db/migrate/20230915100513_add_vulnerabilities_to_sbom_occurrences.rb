# frozen_string_literal: true

class AddVulnerabilitiesToSbomOccurrences < Gitlab::Database::Migration[2.1]
  def change
    add_column :sbom_occurrences, :vulnerabilities, :jsonb, default: []
  end
end

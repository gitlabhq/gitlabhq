# frozen_string_literal: true

class RemoveVulnerabilitiesColumnFromSbomOccurences < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  enable_lock_retries!

  def up
    remove_column :sbom_occurrences, :vulnerabilities
  end

  def down
    add_column :sbom_occurrences, :vulnerabilities, :jsonb, default: []
  end
end

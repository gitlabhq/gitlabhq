# frozen_string_literal: true

class ValidateSbomOccurrencesVulnerabilitiesProjectIdNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    validate_not_null_constraint :sbom_occurrences_vulnerabilities, :project_id
  end

  def down
    # no-op
  end
end

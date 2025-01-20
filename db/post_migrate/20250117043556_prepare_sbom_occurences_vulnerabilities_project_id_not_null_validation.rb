# frozen_string_literal: true

class PrepareSbomOccurencesVulnerabilitiesProjectIdNotNullValidation < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  CONSTRAINT_NAME = :check_a02e48df9c

  def up
    prepare_async_check_constraint_validation :sbom_occurrences_vulnerabilities, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :sbom_occurrences_vulnerabilities, name: CONSTRAINT_NAME
  end
end

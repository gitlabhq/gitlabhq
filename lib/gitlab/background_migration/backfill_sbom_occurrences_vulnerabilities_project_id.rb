# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSbomOccurrencesVulnerabilitiesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_sbom_occurrences_vulnerabilities_project_id
      feature_category :dependency_management
    end
  end
end

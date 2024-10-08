# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDastScannerProfilesBuildsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_dast_scanner_profiles_builds_project_id
      feature_category :dynamic_application_security_testing
    end
  end
end

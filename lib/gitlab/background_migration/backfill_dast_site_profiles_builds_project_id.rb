# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDastSiteProfilesBuildsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_dast_site_profiles_builds_project_id
      feature_category :dynamic_application_security_testing
    end
  end
end

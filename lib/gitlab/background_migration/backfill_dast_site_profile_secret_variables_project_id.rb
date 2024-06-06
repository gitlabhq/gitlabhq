# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDastSiteProfileSecretVariablesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_dast_site_profile_secret_variables_project_id
      feature_category :dynamic_application_security_testing
    end
  end
end

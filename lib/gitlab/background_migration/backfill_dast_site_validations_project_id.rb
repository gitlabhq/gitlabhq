# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDastSiteValidationsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_dast_site_validations_project_id
      feature_category :dynamic_application_security_testing
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillRequirementsManagementTestReportsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_requirements_management_test_reports_project_id
      feature_category :requirements_management
    end
  end
end

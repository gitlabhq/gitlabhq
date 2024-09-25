# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillCiUnitTestFailuresProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_ci_unit_test_failures_project_id
      feature_category :code_testing
    end
  end
end

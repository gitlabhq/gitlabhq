# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillStatusCheckResponsesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_status_check_responses_project_id
      feature_category :compliance_management
    end
  end
end
